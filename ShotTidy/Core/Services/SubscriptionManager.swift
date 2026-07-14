//
//  SubscriptionManager.swift
//  ShotTidy
//
//  StoreKit 2 manager — subscriptions and one-time enrichment packs.
//
//  Product IDs (configure in App Store Connect):
//    com.mbx.shottidier.pro_monthly    — $4.99/month Auto-Renewable Subscription
//    com.mbx.shottidier.enrichments_10 — $1.99  Consumable pack (10 credits)
//    com.mbx.shottidier.enrichments_30 — $4.99  Consumable pack (30 credits)
//    com.mbx.shottidier.enrichments_75 — $9.99  Consumable pack (75 credits)
//

import StoreKit
import SwiftUI

@Observable
@MainActor
final class SubscriptionManager {

    // MARK: - Product IDs

    enum ProductID {
        static let proMonthly     = "com.mbx.shottidier.pro_monthly"
        static let enrichments10  = "com.mbx.shottidier.enrichments_10"
        static let enrichments30  = "com.mbx.shottidier.enrichments_30"
        static let enrichments75  = "com.mbx.shottidier.enrichments_75"

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
        // Warm up the anonymous auth session so the user id is ready for
        // API calls and purchase appAccountToken linking.
        Task { _ = await SupabaseAuthManager.shared.bearerToken() }
        await loadProducts()
        await refreshSubscriptionStatus()
    }

    // MARK: - Load StoreKit products

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: ProductID.all)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            // product load failed — non-critical, UI shows empty paywall
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
        var proJWS: String? = nil
        for await result in Transaction.currentEntitlements {
            guard let tx = try? checkVerified(result) else { continue }
            if tx.productID == ProductID.proMonthly && tx.revocationDate == nil {
                active = true
                proJWS = result.jwsRepresentation
            }
        }

        // Keep the server-side subscription record in sync (once per launch).
        if active, let jws = proJWS, !didLinkSubscriptionThisSession {
            didLinkSubscriptionThisSession = true
            linkSubscriptionOnServer(jws: jws)
        }

        // Read the persisted Pro status BEFORE updating it — this is the value
        // ModelContainer was configured with at launch, so it reflects whether
        // CloudKit sync is currently active in the running container.
        let containerWasConfiguredAsPro = AppGroupManager.loadIsProStatus()
        isProActive = active
        AppGroupManager.saveIsProStatus(active)

        // Only prompt a restart when the sync configuration actually needs to change.
        // Comparing against the persisted launch value prevents a false "Restart Required"
        // alert on initial launch when the container is already correctly configured.
        if containerWasConfiguredAsPro != active {
            needsRestartForSyncChange = true
        }
    }

    /// Set to true when Pro status changes mid-session.
    /// The UI should prompt the user to restart to apply the iCloud sync change.
    private(set) var needsRestartForSyncChange = false

    func acknowledgeRestartPrompt() {
        needsRestartForSyncChange = false
    }

    // MARK: - Private helpers

    private func performPurchase(_ product: Product) async throws -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        purchaseError = nil

        // Tie the purchase to the anonymous Supabase user so App Store Server
        // Notifications can attribute it server-side (appAccountToken).
        var options: Set<Product.PurchaseOption> = []
        if let userId = await SupabaseAuthManager.shared.currentUserId() {
            options.insert(.appAccountToken(userId))
        }

        let result = try await product.purchase(options: options)

        switch result {
        case .success(let verification):
            let tx = try checkVerified(verification)
            if tx.productID == ProductID.proMonthly {
                linkSubscriptionOnServer(jws: verification.jwsRepresentation)
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

    // MARK: - Server-side subscription linking

    /// Guards against re-linking on every status refresh within one launch.
    private var didLinkSubscriptionThisSession = false

    /// Sends the signed transaction to the link-subscription Edge Function so
    /// the server can associate this device's anonymous user with the Pro
    /// subscription. Fire-and-forget: the server upsert is idempotent, and
    /// failures are non-critical (the next launch or ASSN will sync it).
    private func linkSubscriptionOnServer(jws: String) {
        guard let url = URL(string: "\(Config.supabaseURL)/functions/v1/link-subscription") else { return }
        Task.detached {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(
                withJSONObject: ["signedTransaction": jws]
            )
            request.timeoutInterval = 30
            let token = await SupabaseAuthManager.shared.bearerToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: request)
        }
    }
}

// MARK: - Purchase errors

enum PurchaseError: LocalizedError {
    case productNotLoaded

    var errorDescription: String? {
        String(localized: "Product is not available yet. Please try again in a moment.", bundle: AppLocale.bundle)
    }
}
