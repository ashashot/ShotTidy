//
//  MacSettingsView.swift
//  ShotTidierMac
//

import SwiftUI
import SwiftData
import StoreKit

struct MacSettingsView: View {

    @Query private var allItems: [CatalogItem]
    @Query(filter: #Predicate<Screenshot> { $0.extractedItemsCount > 0 })
    private var screenshots: [Screenshot]

    @Environment(\.modelContext) private var modelContext
    @Environment(MacSubscriptionManager.self) private var subscriptionManager
    @Environment(MacCloudSyncMonitor.self) private var syncMonitor
    @Environment(UsageManager.self) private var usageManager
    @Environment(AnalysisEngineSettings.self) private var engineSettings
    @State private var showDeleteAlert = false

    var body: some View {
        Form {
            // MARK: - iCloud Sync / Pro

            if subscriptionManager.isProActive {
                activeProSection
            } else {
                upgradeSection
            }

            // MARK: - Analysis engine

            Section {
                ForEach(AnalysisEngine.allCases) { engine in
                    engineRow(engine)
                }
            } header: {
                Text("Analysis")
            } footer: {
                Text(engineFooter)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Data

            Section("Data") {
                LabeledContent("Catalog items", value: "\(allItems.count)")
                LabeledContent("Screenshots saved", value: "\(screenshots.count)")

                Button("Delete All Data", role: .destructive) {
                    showDeleteAlert = true
                }
            }

            // MARK: - About

            Section("About") {
                LabeledContent("ShotTidier for Mac", value: appVersion)

                Button("Send Feedback") { sendFeedback() }
                Link("Privacy Policy", destination: Config.privacyPolicyURL)
                Link("Terms of Use", destination: Config.termsOfUseURL)
            }
        }
        .formStyle(.grouped)
        .alert("Delete All Data?", isPresented: $showDeleteAlert) {
            Button("Delete All", role: .destructive) { deleteAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All catalog items and saved screenshots will be permanently deleted.")
        }
        .frame(width: 420)
        .navigationTitle("Settings")
        .onAppear { engineSettings.refreshAvailability() }
    }

    // MARK: - Analysis engine

    /// Selectable row for one engine. The on-device option is disabled (with
    /// the reason in the footer) when the model cannot run on this Mac.
    private func engineRow(_ engine: AnalysisEngine) -> some View {
        let isSelected = engineSettings.selectedEngine == engine
        let isAvailable = engine == .cloud || engineSettings.isOnDeviceAvailable
        let isAllowed = engineSettings.isAllowed(engine, isPro: subscriptionManager.isProActive)
        let enabled = isAvailable && isAllowed

        return Button {
            engineSettings.selectedEngine = engine
        } label: {
            HStack(spacing: 12) {
                Image(systemName: engine.iconName)
                    .font(.system(size: 18))
                    .foregroundStyle(enabled ? Color.blue : Color.secondary)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(engine.localizedName)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(enabled ? Color.primary : Color.secondary)
                    Text(engine.localizedSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var engineFooter: String {
        let availability = engineSettings.onDeviceAvailability
        if availability.isAvailable {
            guard engineSettings.selectedEngine == .onDevice else {
                return availability.localizedDescription
            }
            let privacy = "Screenshots are analyzed by Apple Intelligence on this Mac and are never uploaded."
            return availability.isTextOnly ? privacy + " " + availability.localizedDescription : privacy
        }
        if engineSettings.selectedEngine == .onDevice {
            return "On-device analysis is unavailable, so the cloud engine is used. \(availability.localizedDescription)"
        }
        return availability.localizedDescription
    }

    // MARK: - Active Pro section

    private var activeProSection: some View {
        Section("iCloud Sync") {
            LabeledContent("Status") {
                switch syncMonitor.state {
                case .idle:
                    Label("Active", systemImage: "checkmark.icloud.fill")
                        .foregroundStyle(.green)
                case .syncing:
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text("Syncing…").foregroundStyle(.secondary)
                    }
                case .error:
                    Label("Error", systemImage: "exclamationmark.icloud.fill")
                        .foregroundStyle(.red)
                }
            }

            if let date = syncMonitor.lastSyncDate {
                LabeledContent("Last Synced") {
                    Text(date, format: .relative(presentation: .named))
                }
            }

            if let errorMessage = syncMonitor.state.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button {
                syncMonitor.triggerSync(context: modelContext)
            } label: {
                HStack(spacing: 6) {
                    if syncMonitor.isSyncing { ProgressView().controlSize(.small) }
                    Text(syncMonitor.isSyncing ? "Syncing…" : "Sync Now")
                }
            }
            .disabled(syncMonitor.isSyncing)

            if subscriptionManager.needsRestartForSyncChange {
                Label("Restart the app to apply sync changes.", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Upgrade section

    private var upgradeSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "icloud.and.arrow.up.and.arrow.down")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("ShotTidier Pro")
                            .font(.headline)
                        Text("iCloud sync between iPhone and Mac")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let errorMessage = subscriptionManager.purchaseError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                #if DEBUG
                if !subscriptionManager.diagnostic.isEmpty {
                    Text(subscriptionManager.diagnostic)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                        .padding(6)
                        .background(Color(.windowBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                #endif

                HStack(spacing: 8) {
                    // Subscribe button
                    Button {
                        Task {
                            await subscriptionManager.purchasePro()
                            if subscriptionManager.isProActive {
                                usageManager.onSubscriptionActivated()
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if subscriptionManager.isPurchasing {
                                ProgressView().controlSize(.small)
                            }
                            if let product = subscriptionManager.proProduct {
                                Text("Subscribe — \(product.displayPrice)/mo")
                            } else {
                                Text("Subscribe to Pro")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(subscriptionManager.isPurchasing || subscriptionManager.isRestoring)

                    // Restore button
                    Button {
                        Task {
                            await subscriptionManager.restorePurchases()
                            if subscriptionManager.isProActive {
                                usageManager.onSubscriptionActivated()
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            if subscriptionManager.isRestoring {
                                ProgressView().controlSize(.small)
                            }
                            Text(subscriptionManager.isRestoring ? "Restoring…" : "Restore")
                        }
                    }
                    .disabled(subscriptionManager.isPurchasing || subscriptionManager.isRestoring)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("iCloud Sync")
        } footer: {
            Text("Already subscribed on iPhone? Tap **Restore** to activate on this Mac.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    private func sendFeedback() {
        if let url = URL(string: "mailto:\(Config.feedbackEmail)?subject=ShotTidier%20Mac%20Feedback") {
            NSWorkspace.shared.open(url)
        }
    }

    private func deleteAll() {
        for item in allItems { modelContext.delete(item) }
        for shot in screenshots { modelContext.delete(shot) }
        try? modelContext.save()
    }
}
