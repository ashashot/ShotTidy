//
//  UsageManager.swift
//  ShotTidy
//
//  Tracks rolling-30-day screenshot usage and enrichment credit balance.
//  All state is persisted in UserDefaults (local only — by design).
//
//  Free plan limits:
//    • 5 screenshot analyses per rolling 30-day period
//    • 1 enrichment credit on first install (never refills automatically)
//
//  Pro plan ($4.99/month):
//    • Unlimited screenshot analyses
//    • 10 enrichment credits per 30-day period (reset each cycle — do NOT accumulate)
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
    static let proEnrichmentsPerPeriod   = 10
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
    }

    // MARK: - Observable state

    private(set) var screenshotsThisPeriod: Int = 0

    /// Credits from one-time pack purchases — never expire, accumulate across packs.
    private(set) var purchasedCredits: Int = 0

    /// Credits included in the active Pro subscription — reset to proEnrichmentsPerPeriod
    /// each 30-day cycle; unused credits do NOT carry over to the next cycle.
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

    // MARK: - Rolling reset

    /// Call on app launch and whenever subscription status changes.
    ///
    /// - If 30 days have passed since `periodStartDate`, the screenshot counter is reset
    ///   and a new 30-day window begins from **now**.
    /// - If `isPro` and 30 days have passed since `proEnrichmentStartDate`, resets
    ///   Pro credits to `proEnrichmentsPerPeriod` (unused credits do NOT carry over).
    /// - If not Pro, any remaining Pro credits are cleared immediately.
    func performRollingReset(isPro: Bool) {
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

        if isPro {
            // Grant Pro credits if a new 30-day cycle has started.
            grantProCreditsIfDue(now: now)
        } else {
            // Subscription cancelled or inactive — clear Pro credits.
            if proCredits > 0 {
                proCredits = 0
                defaults.set(0, forKey: Key.proCredits)
            }
        }
    }

    /// Called immediately after a successful Pro subscription purchase.
    /// Sets Pro credits to the monthly allowance and starts the Pro window from **now**.
    func onSubscriptionActivated() {
        let now = Date()
        proEnrichmentStartDate = now
        defaults.set(now.timeIntervalSince1970, forKey: Key.proEnrichmentStartDate)
        proCredits = Self.proEnrichmentsPerPeriod
        defaults.set(proCredits, forKey: Key.proCredits)
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

    private func grantProCreditsIfDue(now: Date) {
        let windowStart = proEnrichmentStartDate ?? now
        let nextGrant   = windowStart.addingTimeInterval(Self.periodDays * 86400)

        guard now >= nextGrant else { return }

        // 30-day cycle elapsed — RESET Pro credits (unused credits are lost, not carried over).
        proEnrichmentStartDate = now
        defaults.set(now.timeIntervalSince1970, forKey: Key.proEnrichmentStartDate)
        proCredits = Self.proEnrichmentsPerPeriod
        defaults.set(proCredits, forKey: Key.proCredits)
    }
}
