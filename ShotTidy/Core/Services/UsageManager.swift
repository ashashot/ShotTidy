//
//  UsageManager.swift
//  ShotTidy
//
//  Tracks rolling-30-day screenshot usage and enrichment credit balance.
//  All state is persisted locally in the Keychain-backed UsageStore (by design).
//
//  Free plan limits:
//    • 5 screenshot analyses per rolling 30-day period
//    • 1 enrichment credit on first install (never refills automatically)
//
//  Pro plans (see ProPlan in SubscriptionProducts.swift):
//    • Unlimited screenshot analyses
//    • Monthly ($4.99) / Yearly ($29.99): 10 enrichment credits per 30-day period
//      (reset each cycle — do NOT accumulate)
//    • Lifetime ($49.99 once): 100 enrichment credits once, added to purchasedCredits
//      (granted by the server once per App Store purchase)
//
//  Enrichment packs (one-time purchases — credits added to purchasedCredits immediately):
//    • 10 credits for $1.99
//    • 30 credits for $4.99
//    • 75 credits for $9.99
//
//  Credit spending order: purchasedCredits first, then proCredits.
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class UsageManager {

    // MARK: - Plan limits (constants)

    static let freeScreenshotsPerPeriod  = 5
    static let freeInitialEnrichments    = 1
    static let proEnrichmentsPerPeriod   = ProPlan.monthly.monthlyEnrichments
    /// Number of AI category-field suggestions Pro users get per 30-day period.
    static let proCategorySuggestionsPerPeriod = 5
    static let periodDays: Double        = 30

    // MARK: - UserDefaults keys

    private enum Key {
        static let screenshotsThisPeriod         = "usage.screenshotsThisPeriod"
        static let periodStartDate               = "usage.periodStartDate"
        // Legacy key — kept for migration only; no longer written to after migration.
        static let enrichmentBalance             = "usage.enrichmentBalance"
        static let hasClaimedFreeEnrichment      = "usage.hasClaimedFreeEnrichment"
        static let proEnrichmentStartDate        = "usage.proEnrichmentStartDate"
        static let categorySuggestionsThisPeriod = "usage.categorySuggestionsThisPeriod"
        // New split-credit keys (v2):
        static let purchasedCredits              = "usage.purchasedCredits"
        static let proCredits                    = "usage.proCredits"
        static let lifetimeCreditsClaimed        = "usage.lifetimeCreditsClaimed"
    }

    // MARK: - Observable state

    private(set) var screenshotsThisPeriod: Int = 0

    /// Credits from one-time pack purchases and the Lifetime pool — never
    /// expire, accumulate across purchases.
    private(set) var purchasedCredits: Int = 0

    /// Credits included in an active Monthly / Yearly plan — reset to the plan
    /// allowance each 30-day cycle; unused credits do NOT carry over.
    private(set) var proCredits: Int = 0

    /// Combined visible balance (purchased + pro). Kept as a computed property so UI
    /// code that reads `enrichmentBalance` continues to work without changes.
    var enrichmentBalance: Int { purchasedCredits + proCredits }

    /// AI category-field suggestions used in the current 30-day period (Pro only).
    private(set) var categorySuggestionsThisPeriod: Int = 0

    /// The date when the current 30-day screenshot window started.
    private(set) var periodStartDate: Date = Date()

    /// The date when the current 30-day Pro enrichment window started.
    private(set) var proEnrichmentStartDate: Date?

    /// Prevents overlapping Lifetime claims (launch and plan change can race).
    @ObservationIgnored private var isClaimingLifetimeCredits = false

    private let defaults: UsageStore

    // MARK: - Init

    /// Counters live in the Keychain-backed `UsageStore` so free-tier limits
    /// survive an app delete + reinstall (see [[custom-categories-feature]] sibling note).
    init(defaults: UsageStore = .shared) {
        self.defaults = defaults
        loadFromDefaults()
        claimFreeEnrichmentIfNeeded()
    }

    // MARK: - Computed helpers

    /// Date when the current screenshot period expires.
    var periodEndDate: Date {
        periodStartDate.addingTimeInterval(Self.periodDays * 86400)
    }

    /// Seconds remaining until the screenshot counter resets.
    var secondsUntilReset: TimeInterval {
        max(0, periodEndDate.timeIntervalSinceNow)
    }

    /// Remaining screenshot quota (Int.max for Pro).
    func remainingScreenshots(isPro: Bool) -> Int {
        isPro ? Int.max : max(0, Self.freeScreenshotsPerPeriod - screenshotsThisPeriod)
    }

    /// Whether the user can analyze `count` screenshots right now.
    func canAnalyzeScreenshots(count: Int, isPro: Bool) -> Bool {
        isPro || screenshotsThisPeriod + count <= Self.freeScreenshotsPerPeriod
    }

    /// Whether the user has at least one enrichment credit.
    func canEnrich() -> Bool { enrichmentBalance > 0 }

    /// Remaining AI category-field suggestions (0 for non-Pro).
    func remainingCategorySuggestions(isPro: Bool) -> Int {
        isPro ? max(0, Self.proCategorySuggestionsPerPeriod - categorySuggestionsThisPeriod) : 0
    }

    /// Whether the user can request an AI category-field suggestion right now.
    func canSuggestCategoryFields(isPro: Bool) -> Bool {
        remainingCategorySuggestions(isPro: isPro) > 0
    }

    // MARK: - Consume / add

    /// Records N screenshots as analyzed. Call after a successful analysis batch.
    func consumeScreenshots(count: Int) {
        screenshotsThisPeriod += count
        defaults.set(screenshotsThisPeriod, forKey: Key.screenshotsThisPeriod)
    }

    /// Deducts one enrichment credit. Purchased credits are spent first, then Pro credits.
    func consumeEnrichment() {
        if purchasedCredits > 0 {
            purchasedCredits -= 1
            defaults.set(purchasedCredits, forKey: Key.purchasedCredits)
        } else if proCredits > 0 {
            proCredits -= 1
            defaults.set(proCredits, forKey: Key.proCredits)
        }
    }

    /// Adds enrichment credits from a one-time pack purchase. These never expire.
    func addEnrichments(_ count: Int) {
        purchasedCredits += count
        defaults.set(purchasedCredits, forKey: Key.purchasedCredits)
    }

    /// Records one AI category-field suggestion. Call before the API request.
    func consumeCategorySuggestion() {
        categorySuggestionsThisPeriod += 1
        defaults.set(categorySuggestionsThisPeriod, forKey: Key.categorySuggestionsThisPeriod)
    }

    // MARK: - Plan sync

    /// Brings counters and credits in line with the active plan. Call on launch
    /// and whenever the plan changes; safe to call repeatedly.
    ///
    /// - If 30 days have passed since `periodStartDate`, the screenshot counter is reset
    ///   and a new 30-day window begins from **now**.
    /// - Monthly / Yearly: grants the plan's monthly credits when no 30-day credit
    ///   window is running — first activation, or the previous window elapsed.
    ///   Unused credits do NOT carry over; a restore or relaunch grants nothing extra.
    /// - Lifetime / Free: no monthly credits — any left from a subscription are cleared.
    func applyPlan(_ plan: ProPlan?) {
        let now = Date()

        // Screenshot counter reset (also resets the category-suggestion counter,
        // which shares the same 30-day window).
        if now >= periodEndDate {
            screenshotsThisPeriod = 0
            categorySuggestionsThisPeriod = 0
            periodStartDate = now
            defaults.set(0, forKey: Key.screenshotsThisPeriod)
            defaults.set(0, forKey: Key.categorySuggestionsThisPeriod)
            defaults.set(now.timeIntervalSince1970, forKey: Key.periodStartDate)
        }

        let allowance = plan?.monthlyEnrichments ?? 0
        if allowance > 0 {
            grantProCreditsIfDue(allowance, now: now)
        } else if proCredits > 0 {
            proCredits = 0
            defaults.set(0, forKey: Key.proCredits)
        }
    }

    /// Adds the one-time Lifetime credit pool to the purchased balance. The server
    /// grants it once per App Store purchase, so restoring on another device or
    /// reinstalling does not add it twice; the local flag stops asking once the
    /// server has answered. A failed request (`nil`) is retried on the next call.
    func claimLifetimeCreditsIfNeeded(_ claim: () async -> Int?) async {
        guard !defaults.bool(forKey: Key.lifetimeCreditsClaimed), !isClaimingLifetimeCredits else { return }
        isClaimingLifetimeCredits = true
        defer { isClaimingLifetimeCredits = false }

        guard let granted = await claim() else { return }
        if granted > 0 {
            addEnrichments(granted)
        }
        defaults.set(true, forKey: Key.lifetimeCreditsClaimed)
    }

    // MARK: - Private

    private func loadFromDefaults() {
        screenshotsThisPeriod = defaults.integer(forKey: Key.screenshotsThisPeriod)
        categorySuggestionsThisPeriod = defaults.integer(forKey: Key.categorySuggestionsThisPeriod)

        // Load split credit balances.
        // Migration: if the new keys are absent, treat the legacy enrichmentBalance as
        // purchasedCredits so no credits are lost on upgrade.
        if defaults.object(forKey: Key.purchasedCredits) == nil {
            let legacy = defaults.integer(forKey: Key.enrichmentBalance)
            purchasedCredits = legacy
            defaults.set(purchasedCredits, forKey: Key.purchasedCredits)
            defaults.set(0, forKey: Key.proCredits)
        } else {
            purchasedCredits = defaults.integer(forKey: Key.purchasedCredits)
            proCredits       = defaults.integer(forKey: Key.proCredits)
        }

        // Screenshot period start date (default: now on first launch)
        if let ts = defaults.object(forKey: Key.periodStartDate) as? Double {
            periodStartDate = Date(timeIntervalSince1970: ts)
        } else {
            // First launch — start the period now
            let now = Date()
            periodStartDate = now
            defaults.set(now.timeIntervalSince1970, forKey: Key.periodStartDate)
        }

        // Pro enrichment window start date
        if let ts = defaults.object(forKey: Key.proEnrichmentStartDate) as? Double {
            proEnrichmentStartDate = Date(timeIntervalSince1970: ts)
        }
    }

    private func claimFreeEnrichmentIfNeeded() {
        guard !defaults.bool(forKey: Key.hasClaimedFreeEnrichment) else { return }
        // Free initial enrichment goes to purchasedCredits (it never expires).
        purchasedCredits = Self.freeInitialEnrichments
        defaults.set(purchasedCredits, forKey: Key.purchasedCredits)
        defaults.set(true, forKey: Key.hasClaimedFreeEnrichment)
    }

    private func grantProCreditsIfDue(_ allowance: Int, now: Date) {
        if let windowStart = proEnrichmentStartDate,
           now < windowStart.addingTimeInterval(Self.periodDays * 86400) {
            return  // The current 30-day credit window is still running.
        }

        // New cycle — RESET Pro credits (unused credits are lost, not carried over).
        proEnrichmentStartDate = now
        defaults.set(now.timeIntervalSince1970, forKey: Key.proEnrichmentStartDate)
        proCredits = allowance
        defaults.set(proCredits, forKey: Key.proCredits)
    }
}
