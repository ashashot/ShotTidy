//
//  MacCategoryEditorView.swift
//  ShotTidierMac
//
//  Create or edit a user-defined category.
//

import SwiftUI
import SwiftData

struct MacCategoryEditorView: View {

    var existing: UserCategory? = nil
    var prefillName: String = ""
    var onSaved: ((String) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openSettings) private var openSettings
    @Environment(CategoryStore.self) private var categoryStore
    @Environment(MacSubscriptionManager.self) private var subManager
    @Environment(UsageManager.self) private var usageManager

    @State private var suggestState: SuggestState = .idle
    @State private var name: String
    @State private var iconName: String
    @State private var colorHex: String
    @State private var aiHint: String
    @State private var titleLabel: String
    @State private var subtitleLabel: String
    @State private var linkLabel: String
    @State private var extra1Label: String
    @State private var extra2Label: String
    @State private var notesLabel: String

    init(
        existing: UserCategory? = nil,
        prefillName: String = "",
        onSaved: ((String) -> Void)? = nil
    ) {
        self.existing = existing
        self.prefillName = prefillName
        self.onSaved = onSaved

        _name          = State(initialValue: existing?.name ?? prefillName)
        _iconName      = State(initialValue: existing?.iconName ?? MacCategoryStyleOptions.defaultIcon)
        _colorHex      = State(initialValue: existing?.colorHex ?? MacCategoryStyleOptions.defaultColorHex)
        _aiHint        = State(initialValue: existing?.aiHint ?? "")
        _titleLabel    = State(initialValue: existing?.titleLabel ?? "Title")
        _subtitleLabel = State(initialValue: existing?.subtitleLabel ?? "")
        _linkLabel     = State(initialValue: existing?.linkLabel ?? "")
        _extra1Label   = State(initialValue: existing?.extra1Label ?? "")
        _extra2Label   = State(initialValue: existing?.extra2Label ?? "")
        _notesLabel    = State(initialValue: existing?.notesLabel ?? "")
    }

    private var isEditing: Bool { existing != nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }
    private var selectedColor: Color { Color(hex: colorHex) }

    var body: some View {
        NavigationStack {
            Form {
                previewSection
                nameSection
                iconSection
                colorSection
                fieldsSection
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .keyboardShortcut(.return, modifiers: .command)
                }
            }
            .frame(minWidth: 540, minHeight: 500)
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        Section("Preview") {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selectedColor.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: iconName)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundStyle(selectedColor)
                }
                Text(trimmedName.isEmpty ? "Category Name" : trimmedName)
                    .font(.headline)
                    .foregroundStyle(trimmedName.isEmpty ? .secondary : .primary)
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Name

    private var nameSection: some View {
        Section {
            TextField("e.g. Wines, Gym Workouts", text: $name)
        } header: {
            Text("Name")
        } footer: {
            if trimmedName.isEmpty {
                Text("Required").foregroundStyle(.red)
            }
        }
    }

    // MARK: - Icon

    private var iconSection: some View {
        Section("Icon") {
            let columns = [GridItem(.adaptive(minimum: 46), spacing: 10)]
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(MacCategoryStyleOptions.icons, id: \.self) { symbol in
                    Button {
                        iconName = symbol
                    } label: {
                        Image(systemName: symbol)
                            .font(.system(size: 17))
                            .foregroundStyle(iconName == symbol ? .white : selectedColor)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle().fill(iconName == symbol ? selectedColor : selectedColor.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Color

    private var colorSection: some View {
        Section("Color") {
            let columns = [GridItem(.adaptive(minimum: 36), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(MacCategoryStyleOptions.colorHexes, id: \.self) { hex in
                    let color = Color(hex: hex)
                    Button {
                        colorHex = hex
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(width: 36, height: 36)
                            .overlay(Circle().stroke(Color.primary, lineWidth: colorHex == hex ? 3 : 0))
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .opacity(colorHex == hex ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Fields

    private var fieldsSection: some View {
        Section {
            fieldRow("Primary field (required)", binding: $titleLabel, placeholder: "Title")
            fieldRow("Second field", binding: $subtitleLabel, placeholder: "Leave empty to hide")
            fieldRow("Link field", binding: $linkLabel, placeholder: "Leave empty to hide")
            fieldRow("Third field", binding: $extra1Label, placeholder: "Leave empty to hide")
            fieldRow("Fourth field", binding: $extra2Label, placeholder: "Leave empty to hide")
            fieldRow("Notes field", binding: $notesLabel, placeholder: "Leave empty to hide")
            fieldRow("AI hint (optional)", binding: $aiHint, placeholder: "Describes what belongs in this category")

            if suggestState != .idle {
                suggestStatusRow
            }
        } header: {
            HStack {
                Text("Fields")
                Spacer()
                aiSuggestButton
            }
        } footer: {
            Text("Field labels define the item form for this category. Leave a label empty to hide that field. The AI hint helps automatic categorization during screenshot analysis.")
        }
    }

    // MARK: - AI suggest button

    private var aiSuggestButton: some View {
        let remaining = usageManager.remainingCategorySuggestions(isPro: subManager.isProActive)
        return Button {
            runSuggestion()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                Text(remaining > 0 ? "AI fields (\(remaining))" : "AI fields")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.purple)
        }
        .buttonStyle(.plain)
        .disabled(suggestState == .loading || trimmedName.isEmpty)
    }

    // MARK: - Suggest status row

    @ViewBuilder
    private var suggestStatusRow: some View {
        switch suggestState {
        case .idle:
            EmptyView()
        case .loading:
            HStack(spacing: 12) {
                ProgressView().controlSize(.small).tint(.purple)
                Text("Designing fields…").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
            }
        case .success:
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                Text("Fields suggested — review and adjust").font(.subheadline.weight(.medium))
                Spacer()
            }
        case .failure(let message):
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
                Text(message).font(.subheadline).lineLimit(2)
                Spacer()
                Button("OK") { withAnimation { suggestState = .idle } }
                    .font(.subheadline.weight(.semibold))
            }
        }
    }

    // MARK: - AI suggestion logic

    private func runSuggestion() {
        // The paywall lives in Settings on macOS.
        guard subManager.isProActive else {
            openSettings()
            return
        }
        guard usageManager.canSuggestCategoryFields(isPro: subManager.isProActive) else {
            withAnimation {
                suggestState = .failure("You've used all AI field suggestions for this period.")
            }
            return
        }

        usageManager.consumeCategorySuggestion()
        withAnimation { suggestState = .loading }

        Task {
            do {
                let layout = try await CategorySuggestionClient.shared.suggestFields(
                    name: trimmedName,
                    hint: aiHint
                )
                withAnimation(.spring(duration: 0.35)) {
                    iconName      = layout.iconName
                    titleLabel    = layout.titleLabel
                    subtitleLabel = layout.subtitleLabel
                    linkLabel     = layout.linkLabel
                    extra1Label   = layout.extra1Label
                    extra2Label   = layout.extra2Label
                    notesLabel    = layout.notesLabel
                    if aiHint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        aiHint = layout.aiHint
                    }
                    suggestState = .success
                }
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation { if suggestState == .success { suggestState = .idle } }
                }
            } catch {
                withAnimation { suggestState = .failure(error.localizedDescription) }
            }
        }
    }

    private func fieldRow(_ label: String, binding: Binding<String>, placeholder: String) -> some View {
        LabeledContent(label) {
            TextField(placeholder, text: binding)
                .labelsHidden()
        }
    }

    // MARK: - Save

    private func save() {
        guard canSave else { return }
        let trimTitle = titleLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveTitleLabel = trimTitle.isEmpty ? "Title" : trimTitle

        if let existing {
            existing.name          = trimmedName
            existing.iconName      = iconName
            existing.colorHex      = colorHex
            existing.aiHint        = aiHint.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.titleLabel    = effectiveTitleLabel
            existing.subtitleLabel = subtitleLabel
            existing.linkLabel     = linkLabel
            existing.extra1Label   = extra1Label
            existing.extra2Label   = extra2Label
            existing.notesLabel    = notesLabel
            try? modelContext.save()
            categoryStore.reload()
            onSaved?(existing.key)
        } else {
            let category = UserCategory(
                name:          trimmedName,
                iconName:      iconName,
                colorHex:      colorHex,
                sortOrder:     categoryStore.nextSortOrder,
                aiHint:        aiHint.trimmingCharacters(in: .whitespacesAndNewlines),
                titleLabel:    effectiveTitleLabel,
                subtitleLabel: subtitleLabel,
                linkLabel:     linkLabel,
                extra1Label:   extra1Label,
                extra2Label:   extra2Label,
                notesLabel:    notesLabel
            )
            modelContext.insert(category)
            try? modelContext.save()
            categoryStore.reload()
            onSaved?(category.key)
        }
        dismiss()
    }

    // MARK: - SuggestState

    private enum SuggestState: Equatable {
        case idle
        case loading
        case success
        case failure(String)
    }
}
