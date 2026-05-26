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
//    • +10 enrichment credits every 30 days (from subscription activation or last grant)
//
//  Enrichment packs (one-time purchases — credits added to balance immediately):
//    • 10 credits for $1.99
//    • 30 credits for $4.99
//    • 75 credits for $9.99
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
    static let periodDays: Double        = 30

    // MARK: - UserDefaults keys

    private enum Key {
        static let screenshotsThisPeriod    = "usage.screenshotsThisPeriod"
        static let periodStartDate          = "usage.periodStartDate"
        static let enrichmentBalance        = "usage.enrichmentBalance"
        static let hasClaimedFreeEnrichment = "usage.hasClaimedFreeEnrichment"
        static let proEnrichmentStartDate   = "usage.proEnrichmentStartDate"
    }

    // MARK: - Observable state

    private(set) var screenshotsThisPeriod: Int = 0
    private(set) var enrichmentBalance: Int = 0

    /// The date when the current 30-day screenshot window started.
    private(set) var periodStartDate: Date = Date()

    /// The date when the current 30-day Pro enrichment window started.
    private(set) var proEnrichmentStartDate: Date?

    private let defaults: UserDefaults

    // MARK: - Init

    init(defaults: UserDefaults = AppGroupManager.sharedDefaults) {
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

    // MARK: - Consume / add

    /// Records N screenshots as analyzed. Call after a successful analysis batch.
    func consumeScreenshots(count: Int) {
        screenshotsThisPeriod += count
        defaults.set(screenshotsThisPeriod, forKey: Key.screenshotsThisPeriod)
    }

    /// Deducts one enrichment credit. Call immediately before starting enrichment.
    func consumeEnrichment() {
        guard enrichmentBalance > 0 else { return }
        enrichmentBalance -= 1
        defaults.set(enrichmentBalance, forKey: Key.enrichmentBalance)
    }

    /// Adds enrichment credits (after a pack purchase or rolling Pro grant).
    func addEnrichments(_ count: Int) {
        enrichmentBalance += count
        defaults.set(enrichmentBalance, forKey: Key.enrichmentBalance)
    }

    // MARK: - Rolling reset

    /// Call on app launch and whenever subscription status changes.
    ///
    /// - If 30 days have passed since `periodStartDate`, the screenshot counter is reset
    ///   and a new 30-day window begins from **now**.
    /// - If `isPro` and 30 days have passed since `proEnrichmentStartDate`, grants
    ///   +10 enrichment credits and resets the Pro enrichment window.
    func performRollingReset(isPro: Bool) {
        let now = Date()

        // Screenshot counter reset
        if now >= periodEndDate {
            screenshotsThisPeriod = 0
            periodStartDate = now
            defaults.set(0, forKey: Key.screenshotsThisPeriod)
            defaults.set(now.timeIntervalSince1970, forKey: Key.periodStartDate)
        }

        // Pro enrichment grant (rolling 30 days from last grant)
        if isPro {
            grantProEnrichmentsIfDue(now: now)
        }
    }

    /// Called immediately after a successful Pro subscription purchase.
    /// Grants the first 30-day enrichment credits right away and starts
    /// the Pro enrichment window from **now**.
    func onSubscriptionActivated() {
        let now = Date()
        proEnrichmentStartDate = now
        defaults.set(now.timeIntervalSince1970, forKey: Key.proEnrichmentStartDate)
        addEnrichments(Self.proEnrichmentsPerPeriod)
    }

    // MARK: - Private

    private func loadFromDefaults() {
        screenshotsThisPeriod = defaults.integer(forKey: Key.screenshotsThisPeriod)
        enrichmentBalance     = defaults.integer(forKey: Key.enrichmentBalance)

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
        enrichmentBalance = Self.freeInitialEnrichments
        defaults.set(enrichmentBalance, forKey: Key.enrichmentBalance)
        defaults.set(true, forKey: Key.hasClaimedFreeEnrichment)
    }

    private func grantProEnrichmentsIfDue(now: Date) {
        let windowStart = proEnrichmentStartDate ?? now
        let nextGrant   = windowStart.addingTimeInterval(Self.periodDays * 86400)

        guard now >= nextGrant else { return }

        // 30 days since last grant — add credits and start a new window
        proEnrichmentStartDate = now
        defaults.set(now.timeIntervalSince1970, forKey: Key.proEnrichmentStartDate)
        addEnrichments(Self.proEnrichmentsPerPeriod)
    }
}
