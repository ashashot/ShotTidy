//
//  SettingsView.swift
//  ShotTidy
//
//  Настройки: ввод и управление OpenAI API-ключом.
//

import SwiftUI

struct SettingsView: View {
    @State private var apiKeyInput: String = ""
    @State private var isSaved = false
    @State private var showDeleteAlert = false
    @State private var isKeyVisible = false

    private var currentKey: String? { KeychainManager.shared.getAPIKey() }
    private var hasKey: Bool { KeychainManager.shared.hasAPIKey }

    var body: some View {
        NavigationStack {
            Form {

                // MARK: API Key Section
                Section {
                    if hasKey {
                        savedKeyRow
                    } else {
                        inputKeyRow
                    }
                } header: {
                    Text("OpenAI API-ключ")
                } footer: {
                    Text("Ключ хранится в защищённом Keychain устройства и не передаётся третьим сторонам.")
                }

                // MARK: About Section
                Section("О приложении") {
                    LabeledContent("Версия", value: appVersion)
                    LabeledContent("AI-модель", value: "GPT-4o Vision")
                    LabeledContent("Синхронизация", value: "iCloud CloudKit")
                }

                // MARK: How to get key
                Section("Как получить API-ключ") {
                    Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                        HStack {
                            Image(systemName: "key.horizontal")
                            Text("platform.openai.com/api-keys")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Настройки")
            .alert("Удалить ключ?", isPresented: $showDeleteAlert) {
                Button("Удалить", role: .destructive) {
                    KeychainManager.shared.deleteAPIKey()
                    apiKeyInput = ""
                }
                Button("Отмена", role: .cancel) {}
            } message: {
                Text("Анализ новых скриншотов будет недоступен.")
            }
        }
    }

    // MARK: - Saved Key Row

    private var savedKeyRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Text("Ключ сохранён")
                    .fontWeight(.medium)
                Spacer()
            }

            if let key = currentKey {
                HStack {
                    Text(isKeyVisible ? key : maskedKey(key))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Button {
                        isKeyVisible.toggle()
                    } label: {
                        Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }

            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Удалить ключ", systemImage: "trash")
                    .font(.subheadline)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Input Key Row

    private var inputKeyRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            SecureField("sk-...", text: $apiKeyInput)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(.body, design: .monospaced))

            Button {
                saveKey()
            } label: {
                HStack {
                    Spacer()
                    if isSaved {
                        Label("Сохранено!", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Text("Сохранить")
                            .fontWeight(.semibold)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
                .background(apiKeyInput.isEmpty ? Color(.systemGray5) : Color.blue)
                .foregroundStyle(apiKeyInput.isEmpty ? Color.secondary : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .disabled(apiKeyInput.isEmpty)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Helpers

    private func saveKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        KeychainManager.shared.saveAPIKey(trimmed)
        isSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSaved = false
            apiKeyInput = ""
        }
    }

    private func maskedKey(_ key: String) -> String {
        guard key.count > 8 else { return String(repeating: "•", count: key.count) }
        let prefix = String(key.prefix(7))
        let suffix = String(key.suffix(4))
        return "\(prefix)...\(suffix)"
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}

#Preview {
    SettingsView()
}
