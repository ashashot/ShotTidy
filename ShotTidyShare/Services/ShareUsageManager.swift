//
//  ShareUsageManager.swift
//  ShotTidyShare
//
//  Lightweight mirror of the main app's UsageManager for the Share Extension.
//  Reads and writes the same App Group UserDefaults keys, so both targets
//  always operate on the same counters and balance.
//
//  Credit model (must match UsageManager):
//    • purchasedCredits — one-time pack purchases; never expire; spent first.
//    • proCredits       — included in Pro subscription; reset each 30-day cycle.
//

import Foundation
import SwiftUI

@Observable
@MainActor
final class ShareUsageManager {

    // MARK: - Singleton

    static let shared = ShareUsageManager()

    // MARK: - Constants (must match UsageManager)

    static let freeScreenshotsPerPeriod = 5
    static let freeInitialEnrichments   = 1
    static let proEnrichmentsPerPeriod  = 10
    static let periodDays: Double       = 30

    // MARK: - UserDefaults keys (identical to UsageManager.Key)

    private enum Key {
        static let screenshotsThisPeriod    = "usage.screenshotsThisPeriod"
        static let periodStartDate          = "usage.periodStartDate"
        static let enrichmentBalance        = "usage.enrichmentBalance"  // legacy — migration only
        static let hasClaimedFreeEnrichment = "usage.hasClaimedFreeEnrichment"
        static let proEnrichmentStartDate   = "usage.proEnrichmentStartDate"
        static let purchasedCredits         = "usage.purchasedCredits"
        static let proCredits               = "usage.proCredits"
    }

    // MARK: - Observable state

    private(set) var screenshotsThisPeriod: Int = 0
    private(set) var purchasedCredits: Int = 0
    private(set) var proCredits: Int = 0
    private(set) var periodStartDate: Date = Date()

    /// Combined visible balance.
    var enrichmentBalance: Int { purchasedCredits + proCredits }

    private let defaults: UsageStore

    // MARK: - Init

    private init() {
        defaults = UsageStore.shared
        loadFromDefaults()
        claimFreeEnrichmentIfNeeded()
    }

    // MARK: - Computed

    var periodEndDate: Date {
        periodStartDate.addingTimeInterval(Self.periodDays * 86400)
    }

    func canAnalyzeScreenshots(count: Int, isPro: Bool) -> Bool {
        isPro || screenshotsThisPeriod + count <= Self.freeScreenshotsPerPeriod
    }

    func canEnrich() -> Bool { enrichmentBalance > 0 }

    // MARK: - Consume / add

    func consumeScreenshots(count: Int) {
        screenshotsThisPeriod += count
        defaults.set(screenshotsThisPeriod, forKey: Key.screenshotsThisPeriod)
    }

    /// Deducts one enrichment credit. Purchased credits are spent first.
    func consumeEnrichment() {
        if purchasedCredits > 0 {
            purchasedCredits -= 1
            defaults.set(purchasedCredits, forKey: Key.purchasedCredits)
        } else if proCredits > 0 {
            proCredits -= 1
            defaults.set(proCredits, forKey: Key.proCredits)
        }
    }

    // MARK: - Rolling 30-day reset

    /// Call at the start of each extension session.
    func performRollingReset(isPro: Bool) {
        let now = Date()

        if now >= periodEndDate {
            screenshotsThisPeriod = 0
            periodStartDate = now
            defaults.set(0, forKey: Key.screenshotsThisPeriod)
            defaults.set(now.timeIntervalSince1970, forKey: Key.periodStartDate)
        }

        if isPro {
            grantProCreditsIfDue(now: now)
        } else {
            if proCredits > 0 {
                proCredits = 0
                defaults.set(0, forKey: Key.proCredits)
            }
        }
    }

    // MARK: - Private

    private func loadFromDefaults() {
        screenshotsThisPeriod = defaults.integer(forKey: Key.screenshotsThisPeriod)

        // Migration: if new keys are absent, treat legacy enrichmentBalance as purchasedCredits.
        if defaults.object(forKey: Key.purchasedCredits) == nil {
            let legacy = defaults.integer(forKey: Key.enrichmentBalance)
            purchasedCredits = legacy
            defaults.set(purchasedCredits, forKey: Key.purchasedCredits)
            defaults.set(0, forKey: Key.proCredits)
        } else {
            purchasedCredits = defaults.integer(forKey: Key.purchasedCredits)
            proCredits       = defaults.integer(forKey: Key.proCredits)
        }

        if let ts = defaults.object(forKey: Key.periodStartDate) as? Double {
            periodStartDate = Date(timeIntervalSince1970: ts)
        } else {
            let now = Date()
            periodStartDate = now
            defaults.set(now.timeIntervalSince1970, forKey: Key.periodStartDate)
        }
    }

    private func claimFreeEnrichmentIfNeeded() {
        guard !defaults.bool(forKey: Key.hasClaimedFreeEnrichment) else { return }
        purchasedCredits = Self.freeInitialEnrichments
        defaults.set(purchasedCredits, forKey: Key.purchasedCredits)
        defaults.set(true, forKey: Key.hasClaimedFreeEnrichment)
    }

    private func grantProCreditsIfDue(now: Date) {
        let proKey = Key.proEnrichmentStartDate
        let windowStart: Date
        if let ts = defaults.object(forKey: proKey) as? Double {
            windowStart = Date(timeIntervalSince1970: ts)
        } else {
            windowStart = now
        }
        let nextGrant = windowStart.addingTimeInterval(Self.periodDays * 86400)
        guard now >= nextGrant else { return }

        // Reset Pro credits for the new cycle (no carryover).
        proCredits = Self.proEnrichmentsPerPeriod
        defaults.set(proCredits, forKey: Key.proCredits)
        defaults.set(now.timeIntervalSince1970, forKey: proKey)
    }
}
