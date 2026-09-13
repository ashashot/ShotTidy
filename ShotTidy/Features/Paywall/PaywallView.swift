//
//  PaywallView.swift
//  ShotTidy
//
//  Full-screen Pro paywall: Free vs Pro feature comparison and a plan picker —
//  Yearly, Monthly or a one-time Lifetime purchase. Subscribers open it to
//  change plans; their current plan is marked and cannot be bought again.
//

import SwiftUI
import StoreKit

struct PaywallView: View {

    @Environment(SubscriptionManager.self) private var subManager
    @Environment(UsageManager.self) private var usageManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: ProPlan = .yearly
    @State private var isPurchasing = false
    @State private var isRestoring  = false
    @State private var errorMessage: String?
    @State private var showCancelSubscriptionAlert = false
    @State private var showManageSubscriptions = false

    /// Display order — the yearly plan first as the recommended one.
    private let plans: [ProPlan] = [.yearly, .monthly, .lifetime]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                        .padding(.top, 8)

                    if !subManager.isProActive {
                        usageBannerSection
                            .padding(.top, 20)
                    }

                    featuresSection
                        .padding(.top, 20)

                    plansSection
                        .padding(.top, 20)

                    ctaSection
                        .padding(.top, 16)

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
            .alert("Lifetime Unlocked", isPresented: $showCancelSubscriptionAlert) {
                Button("Manage Subscription") { showManageSubscriptions = true }
                Button("Later", role: .cancel) { dismiss() }
            } message: {
                Text("Your subscription is still active. Cancel it in your App Store account so you are not charged again.")
            }
            .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
            .onChange(of: showManageSubscriptions) { _, isShown in
                if !isShown { dismiss() }
            }
        }
        .onAppear { normalizeSelectedPlan() }
        .onChange(of: subManager.products.map(\.id)) { _, _ in
            normalizeSelectedPlan()
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
                title: String(localized: "Screenshot Analysis", bundle: AppLocale.bundle),
                free: String(localized: "5 / 30 days", bundle: AppLocale.bundle),
                pro: String(localized: "Unlimited", bundle: AppLocale.bundle)
            )
            Divider().padding(.leading, 50)

            FeatureRow(
                icon: "magnifyingglass.circle.fill", color: .purple,
                title: String(localized: "Find Missing Info", bundle: AppLocale.bundle),
                free: String(localized: "1 credit", bundle: AppLocale.bundle),
                pro: String(localized: "10 / 30 days", bundle: AppLocale.bundle)
            )
            Divider().padding(.leading, 50)

            FeatureRow(
                icon: "folder.badge.plus", color: .green,
                title: String(localized: "Custom Categories", bundle: AppLocale.bundle),
                free: "-", pro: "✓"
            )
            Divider().padding(.leading, 50)

            FeatureRow(
                icon: "wand.and.stars", color: .pink,
                title: String(localized: "AI Category Fields", bundle: AppLocale.bundle),
                free: "-", pro: String(localized: "5 / 30 days", bundle: AppLocale.bundle)
            )
            Divider().padding(.leading, 50)

            FeatureRow(
                icon: "icloud.fill", color: .cyan,
                title: String(localized: "CloudKit Sync", bundle: AppLocale.bundle),
                free: "-", pro: "✓"
            )
            Divider().padding(.leading, 50)

            FeatureRow(
                icon: "square.and.arrow.up.fill", color: .orange,
                title: String(localized: "Share Extension", bundle: AppLocale.bundle),
                free: "✓", pro: "✓"
            )
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Plans

    /// Keeps the selection on a plan that can be bought: not the current plan,
    /// and one whose App Store product actually loaded — a product that is not
    /// available yet would otherwise leave the CTA stuck on "Loading…".
    private func normalizeSelectedPlan() {
        let purchasable = plans.filter {
            $0 != subManager.activePlan && subManager.product(for: $0) != nil
        }
        if !purchasable.contains(selectedPlan), let first = purchasable.first {
            selectedPlan = first
        }
    }

    private var plansSection: some View {
        VStack(spacing: 10) {
            ForEach(plans) { plan in
                if let product = subManager.product(for: plan) {
                    PlanOptionRow(
                        title: plan.localizedName,
                        price: priceText(for: plan, product: product),
                        detail: detailText(for: plan, product: product),
                        badge: badgeText(for: plan),
                        isSelected: selectedPlan == plan,
                        isCurrent: subManager.activePlan == plan
                    ) {
                        selectedPlan = plan
                    }
                }
            }
        }
    }

    private func priceText(for plan: ProPlan, product: Product) -> Text {
        switch plan {
        case .monthly:  return Text("\(product.displayPrice) / month")
        case .yearly:   return Text("\(product.displayPrice) / year")
        case .lifetime: return Text(verbatim: product.displayPrice)
        }
    }

    private func detailText(for plan: ProPlan, product: Product) -> Text {
        switch plan {
        case .monthly:
            return Text("Billed monthly")
        case .yearly:
            let perMonth = (product.price / 12).formatted(product.priceFormatStyle)
            return Text("\(perMonth) per month, billed yearly")
        case .lifetime:
            return Text("Pay once · \(SubscriptionProducts.lifetimeEnrichmentCredits) enrichment credits included")
        }
    }

    private func badgeText(for plan: ProPlan) -> Text? {
        guard plan == .yearly, let percent = yearlySavingsPercent else { return nil }
        return Text("Save \(percent)%")
    }

    /// Yearly discount against twelve monthly payments, from live App Store prices.
    private var yearlySavingsPercent: Int? {
        guard
            let monthly = subManager.product(for: .monthly)?.price,
            let yearly = subManager.product(for: .yearly)?.price,
            monthly > 0
        else { return nil }
        let fullYear = monthly * 12
        let saving = NSDecimalNumber(decimal: (fullYear - yearly) / fullYear * 100).doubleValue
        let percent = Int(saving.rounded())
        return percent > 0 ? percent : nil
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: 12) {
            if let product = subManager.product(for: selectedPlan) {
                Button {
                    Task { await buy(selectedPlan) }
                } label: {
                    Group {
                        if isPurchasing {
                            ProgressView().tint(.white)
                        } else {
                            VStack(spacing: 3) {
                                ctaTitle(for: selectedPlan, price: product.displayPrice)
                                    .font(.headline)
                                ctaCaption(for: selectedPlan)
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
                .disabled(isPurchasing || isRestoring || subManager.activePlan == selectedPlan)
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

    private func ctaTitle(for plan: ProPlan, price: String) -> Text {
        switch plan {
        case .monthly:  return Text("Subscribe for \(price) / month")
        case .yearly:   return Text("Subscribe for \(price) / year")
        case .lifetime: return Text("Buy Lifetime for \(price)")
        }
    }

    private func ctaCaption(for plan: ProPlan) -> Text {
        plan.isSubscription
            ? Text("Cancel anytime in App Store Settings")
            : Text("One-time payment, no subscription")
    }

    // MARK: - Footer

    private var footerSection: some View {
        VStack(spacing: 10) {
            Text("Subscriptions renew automatically at the end of each billing period unless cancelled at least 24 hours before. Manage or cancel anytime in your App Store account settings. Lifetime is a one-time purchase.")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            HStack(spacing: 20) {
                Link("Privacy Policy", destination: Config.privacyPolicyURL)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Link("Terms of Use", destination: Config.termsOfUseURL)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    /// Credits for the new plan are granted by ShotTidyApp when `activePlan` changes.
    private func buy(_ plan: ProPlan) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            guard try await subManager.purchase(plan) else { return }
            if plan == .lifetime && subManager.subscriptionRenewsAlongsideLifetime {
                showCancelSubscriptionAlert = true
            } else {
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
                errorMessage = String(localized: "No active subscription found.", bundle: AppLocale.bundle)
            }
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription). Make sure you're signed in with the same Apple ID used to purchase."
        }
    }
}

// MARK: - PlanOptionRow

private struct PlanOptionRow: View {
    let title: String
    let price: Text
    let detail: Text
    let badge: Text?
    let isSelected: Bool
    let isCurrent: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.blue : Color.secondary)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        if isCurrent {
                            tag(Text("Current"), color: .gray)
                        } else if let badge {
                            tag(badge, color: .orange)
                        }
                    }

                    detail
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                price
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.trailing)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .disabled(isCurrent)
        .opacity(isCurrent ? 0.6 : 1)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func tag(_ text: Text, color: Color) -> some View {
        text
            .font(.system(size: 9, weight: .bold))
            .textCase(.uppercase)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
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
