//
//  ShareUsageManager.swift
//  ShotTidyShare
//
//  Lightweight mirror of the main app's UsageManager for the Share Extension.
//  Reads and writes the same App Group UserDefaults keys, so both targets
//  always operate on the same counters and balance.
//
//  Singleton is safe here because the Share Extension process is short-lived
//  and creates a new instance for each invocation.
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
        static let enrichmentBalance        = "usage.enrichmentBalance"
        static let hasClaimedFreeEnrichment = "usage.hasClaimedFreeEnrichment"
        static let proEnrichmentStartDate   = "usage.proEnrichmentStartDate"
    }

    // MARK: - Observable state

    private(set) var screenshotsThisPeriod: Int = 0
    private(set) var enrichmentBalance: Int = 0
    private(set) var periodStartDate: Date = Date()

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

    func consumeEnrichment() {
        guard enrichmentBalance > 0 else { return }
        enrichmentBalance -= 1
        defaults.set(enrichmentBalance, forKey: Key.enrichmentBalance)
    }

    // MARK: - Rolling 30-day reset

    /// Call at the start of each extension session.
    /// Resets the screenshot counter if 30 days have passed since the window opened.
    func performRollingReset(isPro: Bool) {
        let now = Date()

        if now >= periodEndDate {
            screenshotsThisPeriod = 0
            periodStartDate = now
            defaults.set(0, forKey: Key.screenshotsThisPeriod)
            defaults.set(now.timeIntervalSince1970, forKey: Key.periodStartDate)
        }

        if isPro { grantProEnrichmentsIfDue(now: now) }
    }

    // MARK: - Private

    private func loadFromDefaults() {
        screenshotsThisPeriod = defaults.integer(forKey: Key.screenshotsThisPeriod)
        enrichmentBalance     = defaults.integer(forKey: Key.enrichmentBalance)

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
        enrichmentBalance = Self.freeInitialEnrichments
        defaults.set(enrichmentBalance, forKey: Key.enrichmentBalance)
        defaults.set(true, forKey: Key.hasClaimedFreeEnrichment)
    }

    private func grantProEnrichmentsIfDue(now: Date) {
        let proKey = "usage.proEnrichmentStartDate"
        let windowStart: Date
        if let ts = defaults.object(forKey: proKey) as? Double {
            windowStart = Date(timeIntervalSince1970: ts)
        } else {
            windowStart = now
        }
        let nextGrant = windowStart.addingTimeInterval(Self.periodDays * 86400)
        guard now >= nextGrant else { return }
        enrichmentBalance += Self.proEnrichmentsPerPeriod
        defaults.set(enrichmentBalance, forKey: Key.enrichmentBalance)
        defaults.set(now.timeIntervalSince1970, forKey: proKey)
    }
}
