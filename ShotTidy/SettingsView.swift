//
//  SettingsView.swift
//  ShotTidy
//

import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [CatalogItem]
    /// Only count screenshots that actually have saved catalog items (same filter as ScreenshotsView).
    @Query(filter: #Predicate<Screenshot> { $0.extractedItemsCount > 0 })
    private var screenshots: [Screenshot]
    /// Orphaned screenshots with no saved items — kept separately for cleanup.
    @Query(filter: #Predicate<Screenshot> { $0.extractedItemsCount == 0 })
    private var orphanedScreenshots: [Screenshot]

    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Statistics
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
            .alert("Delete All Data?", isPresented: $showDeleteAlert) {
                Button("Delete All", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All catalog items and saved screenshots will be deleted.")
            }
        }
    }

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
