//
//  SettingsView.swift
//  ShotTidy
//

import SwiftUI
import SwiftData

struct SettingsView: View {

    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [CatalogItem]
    @Query private var screenshots: [Screenshot]

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
            .alert("Delete All Data?", isPresented: $showDeleteAlert) {
                Button("Delete All", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("All catalog items and saved screenshots will be deleted.")
            }
        }
    }

    private func deleteAll() {
        for item in allItems { modelContext.delete(item) }
        for shot in screenshots { modelContext.delete(shot) }
        try? modelContext.save()
    }
}
