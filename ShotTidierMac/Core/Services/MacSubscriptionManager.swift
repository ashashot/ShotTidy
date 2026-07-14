//
//  MacSubscriptionManager.swift
//  ShotTidierMac
//
//  Mirrors the iOS SubscriptionManager but without App Group dependency —
//  macOS stores Pro status in UserDefaults.standard (no Share Extension on Mac).
//

import StoreKit
import SwiftUI

@Observable
@MainActor
final class MacSubscriptionManager {

    // MARK: - Constants

    nonisolated static let proProductID = SubscriptionProducts.proMonthly
    nonisolated static var packProductIDs: Set<String> { SubscriptionProducts.packs }
    nonisolated private static let proStatusKey = "subscription.isPro"

    // MARK: - Credit amounts per pack

    nonisolated static func credits(for productID: String) -> Int {
        SubscriptionProducts.credits(for: productID)
    }

    // MARK: - State

    private(set) var isProActive: Bool = false
    /// True until the app is relaunched after a sync-config change —
    /// drives the persistent hint in Settings. Not cleared by the alert.
    private(set) var needsRestartForSyncChange = false
    /// Drives the one-time alert; cleared when the user acknowledges it.
    private(set) var showRestartAlert = false
    private(set) var products: [Product] = []
    private(set) var isPurchasing = false
    private(set) var isRestoring = false
    var purchaseError: String?
    private(set) var diagnostic = ""

    var proProduct: Product? {
        products.first { $0.id == Self.proProductID }
    }

    var packProducts: [Product] {
        products
            .filter { Self.packProductIDs.contains($0.id) }
            .sorted { $0.price < $1.price }
    }

    // MARK: - Private

    private var transactionListenerTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        isProActive = Self.loadIsProStatus()
        startTransactionListener()
    }

    // MARK: - Launch

    func onLaunch() async {
        // Warm up the anonymous auth session so the user id is ready for
        // API calls and purchase appAccountToken linking.
        Task { _ = await SupabaseAuthManager.shared.bearerToken() }
        // Sequential on purpose (matches iOS): the status-refresh fallback
        // reads proProduct, which is only available after products load.
        await loadProducts()
        await refreshSubscriptionStatus()
    }

    func acknowledgeRestartPrompt() {
        showRestartAlert = false
    }

    // MARK: - Product loading

    func loadProducts() async {
        do {
            let loaded = try await Product.products(
                for: Self.packProductIDs.union([Self.proProductID])
            )
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            // non-critical — paywall will show spinner or no price
        }
    }

    // MARK: - Purchase

    func purchasePro() async {
        guard let product = proProduct else { return }
        isPurchasing = true
        purchaseError = nil
        defer { isPurchasing = false }

        do {
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
                linkSubscriptionOnServer(jws: verification.jwsRepresentation)
                await refreshSubscriptionStatus()
                await tx.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            purchaseError = error.localizedDescription
        }
    }

    // MARK: - Purchase enrichment pack

    /// Returns the number of enrichment credits granted (0 on cancel / failure).
    func purchasePack(_ product: Product) async throws -> Int {
        var options: Set<Product.PurchaseOption> = []
        if let userId = await SupabaseAuthManager.shared.currentUserId() {
            options.insert(.appAccountToken(userId))
        }

        let result = try await product.purchase(options: options)
        switch result {
        case .success(let verification):
            let tx = try checkVerified(verification)
            await tx.finish()
            return Self.credits(for: tx.productID)
        case .userCancelled, .pending:
            return 0
        @unknown default:
            return 0
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        isRestoring = true
        purchaseError = nil
        defer { isRestoring = false }

        var syncError: String?
        do {
            try await AppStore.sync()
        } catch {
            // Sync failed (cancelled auth dialog or network) — still check cached entitlements
            syncError = error.localizedDescription
        }

        await refreshSubscriptionStatus()

        if !isProActive {
            if let syncErr = syncError {
                purchaseError = "Sync error: \(syncErr). Checked local transactions — no active Pro found."
            } else {
                purchaseError = "No active Pro subscription found for this Apple ID."
            }
        }
    }

    // MARK: - Status check

    func refreshSubscriptionStatus() async {
        var active = false
        var proJWS: String? = nil
        var totalEntitlements = 0
        var unverifiedCount = 0
        var foundIDs: [String] = []

        for await result in Transaction.currentEntitlements {
            totalEntitlements += 1
            switch result {
            case .verified(let tx):
                foundIDs.append(tx.productID)
                if tx.productID == Self.proProductID && tx.revocationDate == nil {
                    active = true
                    proJWS = result.jwsRepresentation
                }
            case .unverified(_, let error):
                unverifiedCount += 1
                foundIDs.append("UNVERIFIED(\(error.localizedDescription))")
            }
        }

        // Fallback: subscription status API (helps in Sandbox).
        if !active, let product = proProduct {
            if let statuses = try? await product.subscription?.status {
                for status in statuses where status.state == .subscribed || status.state == .inGracePeriod {
                    // Status covers the whole subscription GROUP — make sure
                    // the underlying transaction is for this product.
                    guard case .verified(let tx) = status.transaction,
                          tx.productID == Self.proProductID,
                          tx.revocationDate == nil else { continue }
                    active = true
                    foundIDs.append("via subscription.status")
                }
            }
            // Recover a JWS for server linking — the fallback path has no
            // entitlement transaction, but latest(for:) usually still has one.
            if active, proJWS == nil,
               let latest = await Transaction.latest(for: Self.proProductID) {
                proJWS = latest.jwsRepresentation
            }
        }

        #if DEBUG
        let storefront = await Storefront.current
        #endif
        #if DEBUG
        diagnostic = "entitlements:\(totalEntitlements) unverified:\(unverifiedCount) active:\(active)\nIDs: \(foundIDs.isEmpty ? "none" : foundIDs.joined(separator: ", "))\nexpected: \(Self.proProductID)\nstorefront: \(storefront?.countryCode ?? "unknown")"
        #endif

        // Keep the server-side subscription record in sync (once per launch).
        if active, let jws = proJWS, !didLinkSubscriptionThisSession {
            didLinkSubscriptionThisSession = true
            linkSubscriptionOnServer(jws: jws)
        }

        let containerWasConfiguredAsPro = Self.loadIsProStatus()
        isProActive = active
        UserDefaults.standard.set(active, forKey: Self.proStatusKey)
        // Mirror into the App Group so the Safari extension can read the Pro
        // flag (its process cannot see this app's standard defaults).
        AppGroupManager.saveIsProStatus(active)

        if containerWasConfiguredAsPro != active {
            needsRestartForSyncChange = true
            showRestartAlert = true
        }
    }

    // MARK: - Persisted status (read before ModelContainer is created)

    nonisolated static func loadIsProStatus() -> Bool {
        UserDefaults.standard.bool(forKey: proStatusKey)
    }

    // MARK: - Private

    private func startTransactionListener() {
        transactionListenerTask = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                guard let tx = try? self.checkVerified(result) else { continue }
                if tx.productID == Self.proProductID {
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
