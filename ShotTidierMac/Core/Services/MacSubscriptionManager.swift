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

    nonisolated static let proProductID = "com.mbx.shottidier.pro_monthly"
    nonisolated private static let proStatusKey = "subscription.isPro"

    // MARK: - State

    private(set) var isProActive: Bool = false
    private(set) var needsRestartForSyncChange = false
    private(set) var proProduct: Product?
    private(set) var isPurchasing = false
    private(set) var isRestoring = false
    var purchaseError: String?
    private(set) var diagnostic = ""

    // MARK: - Private

    private var transactionListenerTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        isProActive = Self.loadIsProStatus()
        startTransactionListener()
    }

    // MARK: - Launch

    func onLaunch() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadProduct() }
            group.addTask { await self.refreshSubscriptionStatus() }
        }
    }

    func acknowledgeRestartPrompt() {
        needsRestartForSyncChange = false
    }

    // MARK: - Product loading

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.proProductID])
            proProduct = products.first
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
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let tx = try checkVerified(verification)
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
                }
            case .unverified(_, let error):
                unverifiedCount += 1
                foundIDs.append("UNVERIFIED(\(error.localizedDescription))")
            }
        }

        // Fallback: subscription status API
        if !active, let product = proProduct {
            if let statuses = try? await product.subscription?.status {
                for status in statuses where status.state == .subscribed || status.state == .inGracePeriod {
                    active = true
                    foundIDs.append("via subscription.status")
                }
            }
        }

        diagnostic = "entitlements:\(totalEntitlements) unverified:\(unverifiedCount) active:\(active)\nIDs: \(foundIDs.isEmpty ? "none" : foundIDs.joined(separator: ", "))\nexpected: \(Self.proProductID)"

        let containerWasConfiguredAsPro = Self.loadIsProStatus()
        isProActive = active
        UserDefaults.standard.set(active, forKey: Self.proStatusKey)
        UserDefaults.standard.synchronize()

        if containerWasConfiguredAsPro != active {
            needsRestartForSyncChange = true
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
}
