//
//  ItemEditView.swift
//  ShotTidy
//
//  Screen for adding or editing a catalog item.
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
                        save()
                        dismiss()
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
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
