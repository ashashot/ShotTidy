//
//  PaywallView.swift
//  ShotTidy
//
//  Full-screen subscription paywall shown when the free screenshot limit is reached.
//  Shows a Free vs Pro feature comparison and a subscribe CTA.
//

import SwiftUI
import StoreKit

struct PaywallView: View {

    @Environment(SubscriptionManager.self) private var subManager
    @Environment(UsageManager.self) private var usageManager
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var isRestoring  = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                        .padding(.top, 8)

                    usageBannerSection
                        .padding(.top, 20)

                    featuresSection
                        .padding(.top, 20)

                    ctaSection
                        .padding(.top, 24)

                    footerSection
                        .padding(.top, 14)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(.secondary)
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
        }
        .task {
            if subManager.products.isEmpty {
                await subManager.loadProducts()
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.18), .purple.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)

                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text("Upgrade to Pro")
                .font(.title.bold())

            Text("Analyze unlimited screenshots and get\nenrichment credits every month.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Usage banner (shows current free usage)

    @ViewBuilder
    private var usageBannerSection: some View {
        let used  = usageManager.screenshotsThisPeriod
        let limit = UsageManager.freeScreenshotsPerPeriod
        let ratio = Double(used) / Double(limit)

        VStack(spacing: 8) {
            HStack {
                Text("Screenshots used (30-day period)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(used) / \(limit)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(used >= limit ? .red : .primary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemFill))
                        .frame(height: 6)
                    Capsule()
                        .fill(used >= limit ? Color.red : Color.blue)
                        .frame(width: geo.size.width * min(ratio, 1.0), height: 6)
                        .animation(.spring(duration: 0.5), value: used)
                }
            }
            .frame(height: 6)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Feature comparison

    private var featuresSection: some View {
        VStack(spacing: 0) {
            // Header row
            HStack {
                Spacer()
                Text("FREE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 80)
                Text("PRO")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.blue)
                    .frame(width: 80)
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 4)

            Divider()

            FeatureRow(
                icon: "photo.stack.fill", color: .blue,
                title: "Screenshot Analysis",
                free: "5 / 30 days", pro: "Unlimited"
            )
            Divider().padding(.leading, 50)

            FeatureRow(
                icon: "magnifyingglass.circle.fill", color: .purple,
                title: "Find Missing Info",
                free: "1 credit", pro: "10 / 30 days"
            )
            Divider().padding(.leading, 50)

            FeatureRow(
                icon: "icloud.fill", color: .cyan,
                title: "CloudKit Sync",
                free: "✓", pro: "✓"
            )
            Divider().padding(.leading, 50)

            FeatureRow(
                icon: "square.and.arrow.up.fill", color: .orange,
                title: "Share Extension",
                free: "✓", pro: "✓"
            )
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 12) {
            if let product = subManager.proProduct {
                Button {
                    Task { await buyPro(product: product) }
                } label: {
                    Group {
                        if isPurchasing {
                            ProgressView().tint(.white)
                        } else {
                            VStack(spacing: 3) {
                                Text("Subscribe for \(product.displayPrice) / month")
                                    .font(.headline)
                                Text("Cancel anytime in App Store Settings")
                                    .font(.caption)
                                    .opacity(0.82)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 14))
                .controlSize(.large)
                .disabled(isPurchasing || isRestoring)
            } else {
                // Products still loading
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Loading…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            }

            Button {
                Task { await restore() }
            } label: {
                Group {
                    if isRestoring {
                        ProgressView()
                    } else {
                        Text("Restore Purchase")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(isPurchasing || isRestoring)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        Text("Subscription renews automatically each month. Manage or cancel anytime in your App Store account settings.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
    }

    // MARK: - Actions

    private func buyPro(product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let success = try await subManager.purchasePro()
            if success {
                usageManager.onSubscriptionActivated()
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await subManager.restorePurchases()
            if subManager.isProActive {
                dismiss()
            } else {
                errorMessage = "No active subscription found."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - FeatureRow

private struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let free: String
    let pro: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.system(size: 16))
                .frame(width: 28, alignment: .center)

            Text(title)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(free)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(width: 80)

            Text(pro)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.blue)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
