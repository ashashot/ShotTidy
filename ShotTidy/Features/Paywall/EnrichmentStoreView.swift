//
//  EnrichmentStoreView.swift
//  ShotTidy
//
//  Sheet presented when the enrichment credit balance is zero.
//  Shows available packs and optionally a Pro upgrade teaser.
//

import SwiftUI
import StoreKit

struct EnrichmentStoreView: View {

    @Environment(SubscriptionManager.self) private var subManager
    @Environment(UsageManager.self) private var usageManager
    @Environment(\.dismiss) private var dismiss

    @State private var purchasingID: String?
    @State private var errorMessage: String?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Current balance header
                    balanceHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 16)

                    Divider()

                    // Pack list
                    VStack(spacing: 10) {
                        if subManager.packProducts.isEmpty {
                            ProgressView()
                                .padding(.top, 40)
                        } else {
                            ForEach(Array(subManager.packProducts.enumerated()), id: \.element.id) { index, product in
                                let credits = SubscriptionManager.credits(for: product.id)
                                let isBestValue = credits == 75  // largest pack

                                PackCard(
                                    product: product,
                                    credits: credits,
                                    isBestValue: isBestValue,
                                    isPurchasing: purchasingID == product.id
                                ) {
                                    Task { await buyPack(product) }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)

                    // Pro upgrade teaser (only for free users)
                    if !subManager.isProActive {
                        proTeaser
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                    }

                    // Legal links
                    HStack(spacing: 20) {
                        Link("Privacy Policy", destination: Config.privacyPolicyURL)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Link("Terms of Use", destination: Config.termsOfUseURL)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Find Missing Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Error", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
        .task {
            if subManager.products.isEmpty {
                await subManager.loadProducts()
            }
        }
    }

    // MARK: - Balance header

    private var balanceHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.12))
                    .frame(width: 52, height: 52)
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.purple)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Enrichment Credits")
                    .font(.headline)
                Text("Auto-fills missing catalog fields using AI")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .center, spacing: 0) {
                Text("\(usageManager.enrichmentBalance)")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(usageManager.enrichmentBalance > 0 ? Color.purple : Color.secondary)
                Text("left")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Pro teaser

    private var proTeaser: some View {
        Button {
            dismiss()
            showPaywall = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Get 10 credits every 30 days with Pro")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("Plus unlimited screenshot analysis — $4.99/mo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func buyPack(_ product: Product) async {
        purchasingID = product.id
        defer { purchasingID = nil }
        do {
            let credits = try await subManager.purchasePack(product)
            if credits > 0 {
                usageManager.addEnrichments(credits)
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - PackCard

private struct PackCard: View {
    let product: Product
    let credits: Int
    let isBestValue: Bool
    let isPurchasing: Bool
    let onPurchase: () -> Void

    var body: some View {
        Button(action: onPurchase) {
            HStack(spacing: 14) {
                // Credits badge
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.10))
                        .frame(width: 60, height: 60)
                    VStack(spacing: 0) {
                        Text("\(credits)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(.purple)
                        Text("uses")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(.purple.opacity(0.65))
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(product.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        if isBestValue {
                            Text("BEST VALUE")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.orange)
                                .clipShape(Capsule())
                        }
                    }

                    Text("\(credits) Find Missing Info searches")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Price button
                Group {
                    if isPurchasing {
                        ProgressView()
                            .frame(width: 66, height: 36)
                    } else {
                        Text(product.displayPrice)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color.purple)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isBestValue ? Color.orange.opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isPurchasing)
    }
}
