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
    @Environment(CategoryStore.self) private var categoryStore

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
        } header: {
            Text("Fields")
        } footer: {
            Text("Field labels define the item form for this category. Leave a label empty to hide that field. The AI hint helps automatic categorization during screenshot analysis.")
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
}
