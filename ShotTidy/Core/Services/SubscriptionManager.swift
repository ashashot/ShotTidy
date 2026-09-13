//
//  SubscriptionManager.swift
//  ShotTidy
//
//  StoreKit 2 manager — Pro plans and one-time enrichment packs.
//
//  Product IDs and plan rules (configure in App Store Connect) live in
//  SubscriptionProducts.swift:
//    com.mbx.shottidier.pro_monthly    — $4.99/month  Auto-Renewable Subscription
//    com.mbx.shottidier.pro_yearly     — $29.99/year  Auto-Renewable Subscription (same group)
//    com.mbx.shottidier.pro_lifetime   — $49.99       Non-Consumable
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
        static let proMonthly     = SubscriptionProducts.proMonthly
        static let proYearly      = SubscriptionProducts.proYearly
        static let proLifetime    = SubscriptionProducts.proLifetime
        static let enrichments10  = SubscriptionProducts.enrichments10
        static let enrichments30  = SubscriptionProducts.enrichments30
        static let enrichments75  = SubscriptionProducts.enrichments75

        static var all: Set<String>   { SubscriptionProducts.all }
        static var packs: Set<String> { SubscriptionProducts.packs }
    }

    // MARK: - Credit amounts per pack

    static func credits(for productID: String) -> Int {
        SubscriptionProducts.credits(for: productID)
    }

    // MARK: - Observable state

    /// The purchase that unlocks Pro right now, `nil` on the Free plan.
    private(set) var activePlan: ProPlan?
    var isProActive: Bool { activePlan != nil }

    /// Lifetime is active but a subscription is still set to renew. The App
    /// Store never cancels it on its own, so the UI asks the user to.
    private(set) var subscriptionRenewsAlongsideLifetime = false

    private(set) var products: [Product] = []
    private(set) var isPurchasing = false
    var purchaseError: String?

    /// Monthly plan product — used for "per month" teasers.
    var proProduct: Product? {
        product(for: .monthly)
    }

    func product(for plan: ProPlan) -> Product? {
        products.first { $0.id == plan.productID }
    }

    var packProducts: [Product] {
        products
            .filter { ProductID.packs.contains($0.id) }
            .sorted { $0.price < $1.price }
    }

    // MARK: - Private

    private var transactionListenerTask: Task<Void, Never>?

    /// Signed Lifetime transaction, kept to claim its one-time credit pool.
    private var lifetimeJWS: String?

    // MARK: - Init

    init() {
        // Start from the persisted plan so Pro UI (and the container that was
        // built from the same flag) do not flash Free until StoreKit answers.
        activePlan = AppGroupManager.loadIsProStatus() ? AppGroupManager.loadProPlan() : nil
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

    // MARK: - Purchase a plan

    /// Returns `true` when the purchase went through.
    func purchase(_ plan: ProPlan) async throws -> Bool {
        guard let product = product(for: plan) else {
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

    /// Diagnostic info from the last call to refreshSubscriptionStatus.
    private(set) var lastDiagnostic = ""

    func refreshSubscriptionStatus() async {
        var best: (plan: ProPlan, jws: String)?
        var totalEntitlements = 0
        var unverifiedCount = 0
        var foundProductIDs: [String] = []

        // Several Pro purchases can be active at once — keep the highest plan.
        func consider(_ plan: ProPlan, jws: String) {
            if let current = best, current.plan.rank >= plan.rank { return }
            best = (plan, jws)
        }

        for await result in Transaction.currentEntitlements {
            totalEntitlements += 1
            switch result {
            case .verified(let tx):
                foundProductIDs.append(tx.productID)
                if tx.revocationDate == nil, let plan = ProPlan(productID: tx.productID) {
                    consider(plan, jws: result.jwsRepresentation)
                }
            case .unverified(_, let error):
                unverifiedCount += 1
                foundProductIDs.append("UNVERIFIED(\(error.localizedDescription))")
            }
        }

        // Fallback: check subscription status via Product API (helps in Sandbox).
        if best == nil {
            for status in await subscriptionGroupStatuses()
            where status.state == .subscribed || status.state == .inGracePeriod {
                // Status covers the whole subscription GROUP — take the plan
                // from the underlying transaction.
                guard case .verified(let tx) = status.transaction,
                      tx.revocationDate == nil,
                      let plan = ProPlan(productID: tx.productID) else { continue }
                consider(plan, jws: status.transaction.jwsRepresentation)
            }
        }

        // Products the App Store did not return (not created, not "Ready to Submit",
        // or not propagated to Sandbox yet) are silently missing from the paywall.
        let missingProducts = ProductID.all.subtracting(products.map(\.id)).sorted()
        lastDiagnostic = "Entitlements: \(totalEntitlements), unverified: \(unverifiedCount), IDs: \(foundProductIDs.joined(separator: "|")), plan: \(best?.plan.rawValue ?? "none"), missing products: \(missingProducts.isEmpty ? "none" : missingProducts.joined(separator: "|"))"

        // Keep the server-side subscription record in sync (once per launch).
        if let best, !didLinkSubscriptionThisSession {
            didLinkSubscriptionThisSession = true
            linkSubscriptionOnServer(jws: best.jws)
        }

        // No signal from StoreKit at all: entitlements came back empty and the
        // product-status fallback could not run because the product list never
        // loaded (offline, App Store unreachable). Keep the last known status
        // rather than downgrading Pro to Free — a false flip here would tear
        // down iCloud sync (and flip it back on the next launch) for no reason.
        if best == nil, totalEntitlements == 0, products.isEmpty {
            lastDiagnostic += " — no StoreKit data, keeping previous status"
            return
        }

        if let best, best.plan == .lifetime {
            lifetimeJWS = best.jws
            subscriptionRenewsAlongsideLifetime = await subscriptionWillRenew()
        } else {
            lifetimeJWS = nil
            subscriptionRenewsAlongsideLifetime = false
        }

        // Persist for the next launch (ModelContainer reads this before StoreKit
        // answers) and for the Share Extension. ShotTidyApp observes isProActive
        // and rebuilds the container in place when the value changes.
        activePlan = best?.plan
        AppGroupManager.saveIsProStatus(isProActive)
        AppGroupManager.saveProPlan(activePlan)
    }

    // MARK: - Lifetime credit pool

    /// Asks the server for the one-time Lifetime credit pool. Returns the
    /// credits granted to this user (0 when the purchase was already claimed
    /// by another install), or `nil` when the request failed — retry later.
    func claimLifetimeCredits() async -> Int? {
        guard
            let jws = lifetimeJWS,
            let url = URL(string: "\(Config.supabaseURL)/functions/v1/link-subscription"),
            let data = try? await SupabaseFunctionClient.postJSON(
                ["signedTransaction": jws, "claimLifetimeCredits": true],
                to: url,
                timeout: 30
            ),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let credits = json["lifetime_credits"] as? Int
        else { return nil }
        return credits
    }

    // MARK: - Private helpers

    /// Statuses of the Pro subscription group (empty until products load).
    private func subscriptionGroupStatuses() async -> [Product.SubscriptionInfo.Status] {
        guard
            let product = products.first(where: { SubscriptionProducts.subscriptions.contains($0.id) }),
            let statuses = try? await product.subscription?.status
        else { return [] }
        return statuses
    }

    /// Whether a subscription in the Pro group is still set to renew.
    private func subscriptionWillRenew() async -> Bool {
        await subscriptionGroupStatuses().contains { status in
            guard status.state != .expired, status.state != .revoked,
                  case .verified(let renewal) = status.renewalInfo else { return false }
            return renewal.willAutoRenew
        }
    }

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
            if SubscriptionProducts.proProducts.contains(tx.productID) {
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
                if SubscriptionProducts.proProducts.contains(tx.productID) {
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
    /// purchase. Fire-and-forget: the server upsert is idempotent, and
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
