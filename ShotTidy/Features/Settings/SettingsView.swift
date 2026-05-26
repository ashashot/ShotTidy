//
//  SettingsView.swift
//  ShotTidy
//

import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionManager.self) private var subManager
    @Environment(UsageManager.self)        private var usageManager

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

    var body: some View {
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
                                Text("Unlimited screenshots · 10 enrichments/month")
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
                                Text("5 screenshots/month · 1 enrichment credit")
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

                // MARK: - About

                Section("About") {
                    HStack {
                        Text("ShotTidy")
                        Spacer()
                        Text("v2.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("AI Model", systemImage: "cpu")
                        Spacer()
                        Text("GPT-4o Vision")
                            .foregroundStyle(.secondary)
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
                restoreError = "No active subscription found."
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
