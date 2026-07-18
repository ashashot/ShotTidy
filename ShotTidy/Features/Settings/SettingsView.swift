//
//  SettingsView.swift
//  ShotTidy
//

import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subManager
    @Environment(UsageManager.self)        private var usageManager
    @Environment(LocalizationManager.self) private var localizationManager

    @Query private var allItems: [CatalogItem]
    /// Only count screenshots that actually have saved catalog items (same filter as ScreenshotsView).
    @Query(filter: #Predicate<Screenshot> { $0.extractedItemsCount > 0 })
    private var screenshots: [Screenshot]
    /// Orphaned screenshots with no saved items — kept separately for cleanup.
    @Query(filter: #Predicate<Screenshot> { $0.extractedItemsCount == 0 })
    private var orphanedScreenshots: [Screenshot]

    @State private var showDeleteAlert = false
    @State private var showPaywall = false
    @State private var showEnrichmentStore = false
    @State private var isRestoring = false
    @State private var restoreError: String?
    @State private var syncMonitor = CloudSyncMonitor()
    @State private var showMailUnavailableAlert = false
    @State private var showDiagnostic = false

    /// Diagnostics is hidden by default — tap the version number 5x to reveal it.
    /// Persisted so it doesn't need to be re-unlocked every launch.
    @AppStorage("diagnostics.unlocked") private var diagnosticsUnlocked = false
    @State private var versionTapCount = 0

    var body: some View {
        @Bindable var localizationManager = localizationManager

        NavigationStack {
            Form {

                // MARK: - Subscription / Plan

                Section {
                    // Plan status
                    HStack(spacing: 10) {
                        if subManager.isProActive {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.blue)
                                .font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pro Plan")
                                    .font(.subheadline.weight(.semibold))
                                Text("Unlimited screenshots · \(UsageManager.proEnrichmentsPerPeriod) enrichments/month")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        } else {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 18))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Free Plan")
                                    .font(.subheadline.weight(.semibold))
                                Text("\(UsageManager.freeScreenshotsPerPeriod) screenshots/month · \(UsageManager.freeInitialEnrichments) enrichment credit")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Upgrade") {
                                showPaywall = true
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.blue)
                        }
                    }
                    .padding(.vertical, 2)

                    // Rolling 30-day screenshots
                    HStack {
                        Label("Screenshots (30 days)", systemImage: "photo.stack")
                        Spacer()
                        if subManager.isProActive {
                            Text("Unlimited")
                                .foregroundStyle(.secondary)
                        } else {
                            let used  = usageManager.screenshotsThisPeriod
                            let limit = UsageManager.freeScreenshotsPerPeriod
                            Text("\(used) / \(limit)")
                                .foregroundStyle(used >= limit ? Color.red : Color.secondary)
                        }
                    }

                    // Reset date (free users only)
                    if !subManager.isProActive {
                        HStack {
                            Label("Resets on", systemImage: "clock.arrow.circlepath")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(usageManager.periodEndDate, style: .date)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Enrichment credits
                    HStack {
                        Label("Enrichment credits", systemImage: "magnifyingglass.circle")
                        Spacer()
                        Text("\(usageManager.enrichmentBalance)")
                            .foregroundStyle(usageManager.enrichmentBalance > 0 ? Color.secondary : Color.red)
                        Button {
                            showEnrichmentStore = true
                        } label: {
                            Image(systemName: "plus.circle")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                    }

                    // Restore (for free users)
                    if !subManager.isProActive {
                        Button {
                            Task { await restore() }
                        } label: {
                            if isRestoring {
                                HStack(spacing: 8) {
                                    ProgressView()
                                    Text("Restoring…")
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                Text("Restore Purchase")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .disabled(isRestoring)
                    }

                } header: {
                    Text("Plan")
                }

                // MARK: - Data statistics

                Section("Data") {
                    HStack {
                        Label("Catalog items", systemImage: "list.bullet")
                        Spacer()
                        Text("\(allItems.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Screenshots saved", systemImage: "photo.stack")
                        Spacer()
                        Text("\(screenshots.count)")
                            .foregroundStyle(.secondary)
                    }

                    Button("Delete All Data", role: .destructive) {
                        showDeleteAlert = true
                    }
                }

                // MARK: - Diagnostics (hidden — tap version 5x in About to reveal)

                if diagnosticsUnlocked {
                    Section {
                        NavigationLink {
                            AnalysisLogView()
                        } label: {
                            Label("Analysis Log", systemImage: "doc.text.magnifyingglass")
                        }
                    } header: {
                        Text("Diagnostics")
                    } footer: {
                        Text("Review what happened during screenshot analysis — useful if AI detection seems off and you're asked to fill in details manually.")
                    }
                }

                // MARK: - iCloud Sync

                if subManager.isProActive {
                    Section {
                        // Status row
                        Group {
                            if syncMonitor.isSyncing {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Label("Syncing…", systemImage: "icloud.and.arrow.up")
                                            .foregroundStyle(.secondary)
                                        Spacer()
                                        ProgressView()
                                    }
                                    ProgressView()
                                        .progressViewStyle(.linear)
                                        .tint(.blue)
                                }
                                .padding(.vertical, 2)
                            } else if let errorMsg = syncMonitor.state.errorMessage {
                                VStack(alignment: .leading, spacing: 4) {
                                    Label("Sync Error", systemImage: "exclamationmark.icloud.fill")
                                        .foregroundStyle(.red)
                                    Text(errorMsg)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                                .padding(.vertical, 2)
                            } else {
                                HStack {
                                    Label("Last Synced", systemImage: "checkmark.icloud")
                                    Spacer()
                                    if let date = syncMonitor.lastSyncDate {
                                        Text(date, style: .relative)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("Not yet")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }

                        // Sync Now button
                        Button {
                            syncMonitor.triggerSync(context: modelContext)
                        } label: {
                            Label("Sync Now", systemImage: "arrow.clockwise.icloud")
                        }
                        .disabled(syncMonitor.isSyncing)

                    } header: {
                        Text("iCloud Sync")
                    }
                } else {
                    Section {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                Label("iCloud Sync", systemImage: "lock.icloud")
                                    .foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                        }
                    } header: {
                        Text("iCloud Sync")
                    } footer: {
                        Text("Available with Pro subscription.")
                    }
                }

                // MARK: - Language

                Section {
                    Picker(selection: $localizationManager.selectedLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    } label: {
                        Label("Language", systemImage: "globe")
                    }
                } header: {
                    Text("Language")
                } footer: {
                    Text("Choose a language, or leave it on System Default to follow your device's language settings.")
                }

                // MARK: - About

                Section("About") {
                    HStack {
                        Text("ShotTidier")
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(.secondary)
                            .onTapGesture(count: 5) { showDiagnostic = true }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { registerVersionTap() }
                    Button {
                        sendFeedback()
                    } label: {
                        HStack {
                            Label("Send Feedback", systemImage: "envelope")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Link(destination: Config.privacyPolicyURL) {
                        HStack {
                            Label("Privacy Policy", systemImage: "lock.shield")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Link(destination: Config.termsOfUseURL) {
                        HStack {
                            Label("Terms of Use", systemImage: "doc.text")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear { purgeOrphanedScreenshots() }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showEnrichmentStore) {
                EnrichmentStoreView()
            }
            .alert("Mail Not Available", isPresented: $showMailUnavailableAlert) {
                Button("Copy Email Address") {
                    UIPasteboard.general.string = Config.feedbackEmail
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("No mail app is configured on this device. You can reach us directly at \(Config.feedbackEmail).")
            }
            .alert("Delete All Data?", isPresented: $showDeleteAlert) {
                Button("Delete All", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All catalog items and saved screenshots will be deleted.")
            }
            .alert("Restore Failed", isPresented: Binding(
                get: { restoreError != nil },
                set: { if !$0 { restoreError = nil } }
            )) {
                Button("OK") { restoreError = nil }
            } message: {
                Text(restoreError ?? "")
            }
            .alert("Diagnostics", isPresented: $showDiagnostic) {
                Button("Copy") {
                    UIPasteboard.general.string = diagnosticText
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text(diagnosticText)
            }
        }
    }

    // MARK: - App version

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "v\(version) (\(build))"
    }

<<<<<<< HEAD
    // MARK: - Diagnostics (tap version label 5× to show)

    private var diagnosticText: String {
        let persistedPro = AppGroupManager.loadIsProStatus()
        return """
        isProActive: \(subManager.isProActive)
        persisted isPro: \(persistedPro)
        products loaded: \(subManager.products.count)
        lastDiagnostic: \(subManager.lastDiagnostic.isEmpty ? "—" : subManager.lastDiagnostic)
        appVersion: \(appVersion)
        """
=======
    /// Tapping the version row 5x reveals the Diagnostics section.
    private func registerVersionTap() {
        guard !diagnosticsUnlocked else { return }
        versionTapCount += 1
        if versionTapCount >= 5 {
            diagnosticsUnlocked = true
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
>>>>>>> main
    }

    // MARK: - Feedback

    private func sendFeedback() {
        guard let url = FeedbackComposer.feedbackMailURL(isPro: subManager.isProActive) else {
            showMailUnavailableAlert = true
            return
        }
        UIApplication.shared.open(url) { success in
            if !success {
                showMailUnavailableAlert = true
            }
        }
    }

    // MARK: - Restore purchases

    private func restore() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await subManager.restorePurchases()
            if subManager.isProActive {
                usageManager.onSubscriptionActivated()
            } else {
                restoreError = String(localized: "No active subscription found.", bundle: AppLocale.bundle)
            }
        } catch {
            restoreError = error.localizedDescription
        }
    }

    // MARK: - Data management

    /// Deletes Screenshot records with no saved catalog items.
    /// These are leftovers from failed or cancelled imports.
    private func purgeOrphanedScreenshots() {
        guard !orphanedScreenshots.isEmpty else { return }
        for shot in orphanedScreenshots {
            modelContext.delete(shot)
        }
        try? modelContext.save()
    }

    private func deleteAll() {
        for item in allItems { modelContext.delete(item) }
        for shot in screenshots { modelContext.delete(shot) }
        for shot in orphanedScreenshots { modelContext.delete(shot) }
        try? modelContext.save()
    }
}
