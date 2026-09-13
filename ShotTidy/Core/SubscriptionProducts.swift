//
//  SubscriptionProducts.swift
//  ShotTidy
//
//  Single source of truth for App Store product identifiers, the Pro plans
//  they unlock and the credit amounts granted by enrichment packs. Compiled
//  into the iOS app, the Share Extension and the macOS app so the plan rules
//  cannot drift.
//
//  Plans (all unlock the same Pro features):
//    com.mbx.shottidier.pro_monthly  — $4.99/month  auto-renewable, 10 credits / 30 days
//    com.mbx.shottidier.pro_yearly   — $29.99/year  auto-renewable, 10 credits / 30 days
//    com.mbx.shottidier.pro_lifetime — $49.99 once  non-consumable, 100 credits once
//

import Foundation

enum SubscriptionProducts {

    static let proMonthly     = "com.mbx.shottidier.pro_monthly"
    static let proYearly      = "com.mbx.shottidier.pro_yearly"
    static let proLifetime    = "com.mbx.shottidier.pro_lifetime"
    static let enrichments10  = "com.mbx.shottidier.enrichments_10"
    static let enrichments30  = "com.mbx.shottidier.enrichments_30"
    static let enrichments75  = "com.mbx.shottidier.enrichments_75"

    /// One-time enrichment credit pool bundled with Lifetime. The server grants
    /// it once per App Store purchase (`link-subscription`, `credit_grants`).
    static let lifetimeEnrichmentCredits = 100

    /// Auto-renewable subscriptions — one subscription group.
    static var subscriptions: Set<String> {
        [proMonthly, proYearly]
    }

    /// Every product that unlocks Pro.
    static var proProducts: Set<String> {
        subscriptions.union([proLifetime])
    }

    static var packs: Set<String> {
        [enrichments10, enrichments30, enrichments75]
    }

    static var all: Set<String> {
        packs.union(proProducts)
    }

    /// Credits granted by a consumable enrichment pack (0 for other products).
    static func credits(for productID: String) -> Int {
        switch productID {
        case enrichments10: return 10
        case enrichments30: return 30
        case enrichments75: return 75
        default: return 0
        }
    }
}

// MARK: - ProPlan

/// The purchase that currently unlocks Pro. Every plan unlocks the same
/// features; plans differ only in billing and in how enrichment credits arrive.
enum ProPlan: String, CaseIterable, Identifiable, Sendable {
    case monthly
    case yearly
    case lifetime

    var id: String { rawValue }

    init?(productID: String) {
        switch productID {
        case SubscriptionProducts.proMonthly:  self = .monthly
        case SubscriptionProducts.proYearly:   self = .yearly
        case SubscriptionProducts.proLifetime: self = .lifetime
        default: return nil
        }
    }

    var productID: String {
        switch self {
        case .monthly:  return SubscriptionProducts.proMonthly
        case .yearly:   return SubscriptionProducts.proYearly
        case .lifetime: return SubscriptionProducts.proLifetime
        }
    }

    var isSubscription: Bool { self != .lifetime }

    /// Enrichment credits granted every 30 days (reset, never accumulated).
    /// Lifetime gets `SubscriptionProducts.lifetimeEnrichmentCredits` once instead.
    var monthlyEnrichments: Int {
        switch self {
        case .monthly, .yearly: return 10
        case .lifetime:         return 0
        }
    }

    /// Higher wins when several Pro purchases are active at once — e.g. a
    /// Lifetime bought while a subscription is still running.
    var rank: Int {
        switch self {
        case .monthly:  return 0
        case .yearly:   return 1
        case .lifetime: return 2
        }
    }

    var localizedName: String {
        switch self {
        case .monthly:  return String(localized: "Monthly", bundle: AppLocale.bundle)
        case .yearly:   return String(localized: "Yearly", bundle: AppLocale.bundle)
        case .lifetime: return String(localized: "Lifetime", bundle: AppLocale.bundle)
        }
    }
}

// MARK: - Persistence (App Group)

extension AppGroupManager {
    private nonisolated static let proPlanKey = "subscription.plan"

    /// Written by the app's subscription manager next to the Pro flag, so the
    /// Share Extension grants credits by the same plan rules.
    nonisolated static func saveProPlan(_ plan: ProPlan?) {
        if let plan {
            sharedDefaults.set(plan.rawValue, forKey: proPlanKey)
        } else {
            sharedDefaults.removeObject(forKey: proPlanKey)
        }
    }

    /// The saved plan. Installs updated from a version that stored only the Pro
    /// flag read as `.monthly` (the only plan back then) until StoreKit refreshes.
    nonisolated static func loadProPlan() -> ProPlan? {
        if let raw = sharedDefaults.string(forKey: proPlanKey) {
            return ProPlan(rawValue: raw)
        }
        return loadIsProStatus() ? .monthly : nil
    }
}
