//
//  SubscriptionManager.swift
//  ShotTidy
//
//  StoreKit 2 manager — subscriptions and one-time enrichment packs.
//
//  Product IDs (configure in App Store Connect):
//    com.mbxsolutions.shottidy.pro_monthly    — $4.99/month Auto-Renewable Subscription
//    com.mbxsolutions.shottidy.enrichments_10 — $1.99  Non-Consumable pack (10 credits)
//    com.mbxsolutions.shottidy.enrichments_30 — $4.99  Non-Consumable pack (30 credits)
//    com.mbxsolutions.shottidy.enrichments_75 — $9.99  Non-Consumable pack (75 credits)
//

import StoreKit
import SwiftUI

@Observable
@MainActor
final class SubscriptionManager {

    // MARK: - Product IDs

    enum ProductID {
        static let proMonthly     = "com.mbxsolutions.shottidy.pro_monthly"
        static let enrichments10  = "com.mbxsolutions.shottidy.enrichments_10"
        static let enrichments30  = "com.mbxsolutions.shottidy.enrichments_30"
        static let enrichments75  = "com.mbxsolutions.shottidy.enrichments_75"

        static var all: Set<String> {
            [proMonthly, enrichments10, enrichments30, enrichments75]
        }
        static var packs: Set<String> {
            [enrichments10, enrichments30, enrichments75]
        }
    }

    // MARK: - Credit amounts per pack

    static func credits(for productID: String) -> Int {
        switch productID {
        case ProductID.enrichments10: return 10
        case ProductID.enrichments30: return 30
        case ProductID.enrichments75: return 75
        default: return 0
        }
    }

    // MARK: - Observable state

    private(set) var isProActive = false
    private(set) var products: [Product] = []
    private(set) var isPurchasing = false
    var purchaseError: String?

    var proProduct: Product? {
        products.first { $0.id == ProductID.proMonthly }
    }

    var packProducts: [Product] {
        products
            .filter { ProductID.packs.contains($0.id) }
            .sorted { $0.price < $1.price }
    }

    // MARK: - Private

    private var transactionListenerTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        startTransactionListener()
    }
    // Note: SubscriptionManager lives for the entire app lifetime (held by @State in ShotTidyApp),
    // so we do not need to cancel transactionListenerTask in deinit.
    // The Task references [weak self] and safely terminates when self is gone.

    // MARK: - Launch sequence (call once from App)

    func onLaunch() async {
        await loadProducts()
        await refreshSubscriptionStatus()
    }

    // MARK: - Load StoreKit products

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: ProductID.all)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            print("[StoreKit] Product load failed: \(error)")
        }
    }

    // MARK: - Purchase subscription

    /// Returns `true` when Pro was activated.
    func purchasePro() async throws -> Bool {
        guard let product = proProduct else {
            throw PurchaseError.productNotLoaded
        }
        return try await performPurchase(product)
    }

    /// Returns the number of enrichment credits granted (0 on cancel / failure).
    func purchasePack(_ product: Product) async throws -> Int {
        let success = try await performPurchase(product)
        return success ? SubscriptionManager.credits(for: product.id) : 0
    }

    // MARK: - Restore purchases

    func restorePurchases() async throws {
        try await AppStore.sync()
        await refreshSubscriptionStatus()
    }

    // MARK: - Subscription status

    func refreshSubscriptionStatus() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard let tx = try? checkVerified(result) else { continue }
            if tx.productID == ProductID.proMonthly && tx.revocationDate == nil {
                active = true
            }
        }
        isProActive = active
        // Sync Pro status to the App Group so the Share Extension can read it
        AppGroupManager.saveIsProStatus(active)
    }

    // MARK: - Private helpers

    private func performPurchase(_ product: Product) async throws -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        purchaseError = nil

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let tx = try checkVerified(verification)
            if tx.productID == ProductID.proMonthly {
                await refreshSubscriptionStatus()
            }
            await tx.finish()
            return true

        case .userCancelled, .pending:
            return false

        @unknown default:
            return false
        }
    }

    private func startTransactionListener() {
        transactionListenerTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard let tx = try? self.checkVerified(result) else { continue }
                if tx.productID == ProductID.proMonthly {
                    await self.refreshSubscriptionStatus()
                }
                await tx.finish()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }
}

// MARK: - Purchase errors

enum PurchaseError: LocalizedError {
    case productNotLoaded

    var errorDescription: String? {
        "Product is not available yet. Please try again in a moment."
    }
}
