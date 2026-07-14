//
//  SubscriptionProducts.swift
//  ShotTidy
//
//  Single source of truth for App Store product identifiers and the credit
//  amounts granted by consumable enrichment packs. Compiled into the iOS app
//  and the macOS app so the two subscription managers cannot drift.
//

import Foundation

enum SubscriptionProducts {

    static let proMonthly     = "com.mbx.shottidier.pro_monthly"
    static let enrichments10  = "com.mbx.shottidier.enrichments_10"
    static let enrichments30  = "com.mbx.shottidier.enrichments_30"
    static let enrichments75  = "com.mbx.shottidier.enrichments_75"

    static var packs: Set<String> {
        [enrichments10, enrichments30, enrichments75]
    }

    static var all: Set<String> {
        packs.union([proMonthly])
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
