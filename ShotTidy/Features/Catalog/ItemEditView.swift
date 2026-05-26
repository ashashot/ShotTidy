//
//  ItemEditView.swift
//  ShotTidy
//
//  Screen for adding or editing a catalog item.
//  Performs real-time duplicate detection while the user types.
//

import SwiftUI
import SwiftData

struct ItemEditView: View {
    let category: ItemCategory
    var existingItem: CatalogItem?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var subtitle: String
    @State private var link: String
    @State private var extra1: String
    @State private var extra2: String
    @State private var notes: String

    // MARK: - Duplicate detection
    @State private var duplicates: [DuplicateMatch] = []
    @State private var showDuplicateConfirm = false

    init(category: ItemCategory, item: CatalogItem?) {
        self.category = category
        self.existingItem = item
        _title    = State(initialValue: item?.title ?? "")
        _subtitle = State(initialValue: item?.subtitle ?? "")
        _link     = State(initialValue: item?.link ?? "")
        _extra1   = State(initialValue: item?.extra1 ?? "")
        _extra2   = State(initialValue: item?.extra2 ?? "")
        _notes    = State(initialValue: item?.notes ?? "")
    }

    private var isEditing: Bool { existingItem != nil }
    private var schema: ItemCategory.FieldSchema { category.fieldSchema }
    private var canSave: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// Key used to trigger the debounced duplicate check.
    /// Changes whenever any of the fields used for matching change.
    private var duplicateCheckKey: String {
        "\(title)|\(subtitle)|\(link)"
    }

    var body: some View {
        NavigationStack {
            Form {
                // Title (required)
                Section {
                    TextField(schema.titlePlaceholder, text: $title, axis: .vertical)
                        .lineLimit(3, reservesSpace: false)
                } header: {
                    Text(schema.titleLabel)
                } footer: {
                    if title.isEmpty {
                        Text("Required field")
                            .foregroundStyle(.red)
                    }
                }

                // Duplicate warning — shown between title and subtitle
                if !duplicates.isEmpty {
                    duplicateWarningSection
                }

                // Subtitle
                if let label = schema.subtitleLabel {
                    Section(label) {
                        TextField(schema.subtitlePlaceholder ?? "", text: $subtitle, axis: .vertical)
                            .lineLimit(4, reservesSpace: false)
                    }
                }

                // Link
                if let label = schema.linkLabel {
                    Section(label) {
                        TextField(schema.linkPlaceholder ?? "https://...", text: $link)
                            .keyboardType(schema.isLinkEmail ? .emailAddress : .URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                // Extra field 1
                if let label = schema.extra1Label {
                    Section(label) {
                        TextField(schema.extra1Placeholder ?? "", text: $extra1)
                    }
                }

                // Extra field 2
                if let label = schema.extra2Label {
                    Section(label) {
                        TextField(schema.extra2Placeholder ?? "", text: $extra2)
                    }
                }

                // Notes
                if let label = schema.notesLabel {
                    Section(label) {
                        TextField(schema.notesPlaceholder ?? label, text: $notes, axis: .vertical)
                            .lineLimit(6, reservesSpace: false)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit" : "Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // When adding a new item and duplicates are detected, ask for confirmation.
                        // When editing an existing item, save directly (user intentionally chose to edit).
                        if !isEditing && !duplicates.isEmpty {
                            showDuplicateConfirm = true
                        } else {
                            save()
                            dismiss()
                        }
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
            // Confirmation alert when saving despite duplicates
            .alert("Possible Duplicate", isPresented: $showDuplicateConfirm) {
                Button("Save Anyway", role: .destructive) {
                    save()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(duplicateAlertMessage)
            }
            // Debounced duplicate check: fires 400 ms after duplicateCheckKey changes.
            // Cancelled automatically when the key changes again before the delay elapses.
            .task(id: duplicateCheckKey) {
                guard canSave else {
                    duplicates = []
                    return
                }
                // 400 ms debounce — avoids querying on every keystroke
                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else { return }

                duplicates = DuplicateChecker.findDuplicates(
                    for: title,
                    subtitle: subtitle.isEmpty ? nil : subtitle,
                    link: link.isEmpty ? nil : link,
                    category: category,
                    excludingId: existingItem?.id,
                    in: modelContext
                )
            }
        }
    }

    // MARK: - Duplicate warning section

    @ViewBuilder
    private var duplicateWarningSection: some View {
        Section {
            ForEach(duplicates) { match in
                HStack(spacing: 10) {
                    Image(systemName: match.confidence.icon)
                        .foregroundStyle(match.confidence.color)
                        .font(.subheadline)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(match.item.title)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                        if let sub = match.item.subtitle {
                            Text(sub)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Text(match.reason)
                            .font(.caption2)
                            .foregroundStyle(match.confidence.color)
                    }

                    Spacer()
                }
                .padding(.vertical, 2)
            }
            .listRowBackground(Color.orange.opacity(0.07))
        } header: {
            HStack(spacing: 5) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption)
                Text(duplicates.count == 1
                     ? "Possible Duplicate"
                     : "Possible Duplicates (\(duplicates.count))")
            }
            .foregroundStyle(.orange)
        } footer: {
            Text("You can still save — duplicates are shown as a warning only.")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Alert message

    private var duplicateAlertMessage: String {
        let topNames = duplicates.prefix(2)
            .map { "\u{201C}\($0.item.title)\u{201D}" }
            .joined(separator: ", ")
        if duplicates.count == 1 {
            return "An item with the same title already exists: \(topNames). Save anyway?"
        } else {
            return "\(duplicates.count) similar items already exist: \(topNames)\(duplicates.count > 2 ? "…" : ""). Save anyway?"
        }
    }

    // MARK: - Save

    private func save() {
        if let existing = existingItem {
            existing.title    = title.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.subtitle = subtitle.isEmpty ? nil : subtitle
            existing.link     = link.isEmpty ? nil : link
            existing.extra1   = extra1.isEmpty ? nil : extra1
            existing.extra2   = extra2.isEmpty ? nil : extra2
            existing.notes    = notes.isEmpty ? nil : notes
        } else {
            let item = CatalogItem(
                category: category,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                subtitle: subtitle.isEmpty ? nil : subtitle,
                link: link.isEmpty ? nil : link,
                extra1: extra1.isEmpty ? nil : extra1,
                extra2: extra2.isEmpty ? nil : extra2,
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(item)
        }
    }
}
