//
//  MacSettingsView.swift
//  ShotTidyMac
//

import SwiftUI
import SwiftData

struct MacSettingsView: View {

    @Query private var allItems: [CatalogItem]
    @Query(filter: #Predicate<Screenshot> { $0.extractedItemsCount > 0 })
    private var screenshots: [Screenshot]

    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteAlert = false

    var body: some View {
        Form {
            // MARK: - Statistics

            Section("Data") {
                LabeledContent("Catalog items", value: "\(allItems.count)")
                LabeledContent("Screenshots saved", value: "\(screenshots.count)")

                Button("Delete All Data", role: .destructive) {
                    showDeleteAlert = true
                }
            }

            // MARK: - About

            Section("About") {
                LabeledContent("ShotTidy for Mac", value: appVersion)

                Button("Send Feedback") {
                    sendFeedback()
                }

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
        .frame(width: 400)
        .navigationTitle("Settings")
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }

    private func sendFeedback() {
        if let url = URL(string: "mailto:\(Config.feedbackEmail)?subject=ShotTidy%20Mac%20Feedback") {
            NSWorkspace.shared.open(url)
        }
    }

    private func deleteAll() {
        for item in allItems { modelContext.delete(item) }
        for shot in screenshots { modelContext.delete(shot) }
        try? modelContext.save()
    }
}

// MARK: - Pane identifiers for TabView-based Settings window

enum SettingsPane: String, CaseIterable {
    case general = "General"

    var icon: String {
        switch self {
        case .general: return "gear"
        }
    }
}
