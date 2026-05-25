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
                // MARK: - API Ключ
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
                            Text(savedAnimation ? "Сохранено ✓" : "Сохранить ключ")
                                .foregroundStyle(savedAnimation ? .green : .blue)
                            Spacer()
                        }
                    }
                    .disabled(apiKeyInput.isEmpty)

                } header: {
                    Text("OpenAI API-ключ")
                } footer: {
                    Text("Получите ключ на platform.openai.com. Хранится в защищённом Keychain.")
                }

                // MARK: - Статистика
                Section("Данные") {
                    HStack {
                        Label("Записей в каталоге", systemImage: "list.bullet")
                        Spacer()
                        Text("\(allItems.count)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Скриншотов сохранено", systemImage: "photo.stack")
                        Spacer()
                        Text("\(screenshots.count)")
                            .foregroundStyle(.secondary)
                    }

                    Button("Удалить все данные", role: .destructive) {
                        showDeleteAlert = true
                    }
                }

                // MARK: - О приложении
                Section("О приложении") {
                    HStack {
                        Text("ShotTidy")
                        Spacer()
                        Text("v2.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Label("Модель AI", systemImage: "cpu")
                        Spacer()
                        Text("GPT-4o Vision")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Настройки")
            .alert("Удалить все данные?", isPresented: $showDeleteAlert) {
                Button("Удалить всё", role: .destructive) { deleteAll() }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Все записи каталога и сохранённые скриншоты будут удалены. API-ключ останется.")
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
