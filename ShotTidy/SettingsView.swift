//
//  SettingsView.swift
//  ShotTidy
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @State private var apiKeyInput: String = ""
    @State private var showAPIKey: Bool = false
    @State private var savedAnimation: Bool = false

    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [CatalogItem]
    @Query private var screenshots: [Screenshot]

    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - API Key
                Section {
                    HStack {
                        if showAPIKey {
                            TextField("sk-...", text: $apiKeyInput)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("sk-...", text: $apiKeyInput)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                        }
                        Button {
                            showAPIKey.toggle()
                        } label: {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        KeychainManager.shared.openAIAPIKey = trimmed.isEmpty ? nil : trimmed
                        withAnimation { savedAnimation = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation { savedAnimation = false }
                        }
                    } label: {
                        HStack {
                            Text(savedAnimation ? "Saved ✓" : "Save Key")
                                .foregroundStyle(savedAnimation ? .green : .blue)
                            Spacer()
                        }
                    }
                    .disabled(apiKeyInput.isEmpty)

                } header: {
                    Text("OpenAI API Key")
                } footer: {
                    Text("Get your key at platform.openai.com. Stored securely in Keychain.")
                }

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
                Text("All catalog items and saved screenshots will be deleted. The API key will remain.")
            }
        }
        .onAppear {
            apiKeyInput = KeychainManager.shared.openAIAPIKey ?? ""
        }
    }

    private func deleteAll() {
        for item in allItems { modelContext.delete(item) }
        for shot in screenshots { modelContext.delete(shot) }
        try? modelContext.save()
    }
}
