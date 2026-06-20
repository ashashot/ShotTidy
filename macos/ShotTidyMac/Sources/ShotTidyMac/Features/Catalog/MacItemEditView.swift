//
//  MacItemEditView.swift
//  ShotTidyMac
//
//  Add or edit a catalog item. Field layout is driven by FieldSchema.
//

import SwiftUI
import SwiftData

struct MacItemEditView: View {

    let descriptor: CategoryDescriptor
    let item: CatalogItem?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var subtitle = ""
    @State private var link = ""
    @State private var extra1 = ""
    @State private var extra2 = ""
    @State private var notes = ""
    @State private var isCompleted = false

    private var schema: ItemCategory.FieldSchema { descriptor.fieldSchema }
    private var isEditing: Bool { item != nil }

    var body: some View {
        NavigationStack {
            Form {
                // Title (always shown)
                Section(schema.titleLabel) {
                    TextField(schema.titlePlaceholder, text: $title, axis: .vertical)
                        .lineLimit(1...4)
                }

                // Optional fields
                if let label = schema.subtitleLabel {
                    Section(label) {
                        TextField(schema.subtitlePlaceholder ?? label, text: $subtitle, axis: .vertical)
                            .lineLimit(1...3)
                    }
                }

                if let label = schema.linkLabel {
                    Section(label) {
                        TextField(schema.linkPlaceholder ?? (schema.isLinkEmail ? "email@example.com" : "https://..."), text: $link)
                    }
                }

                if let label = schema.extra1Label {
                    Section(label) {
                        TextField(schema.extra1Placeholder ?? label, text: $extra1)
                    }
                }

                if let label = schema.extra2Label {
                    Section(label) {
                        TextField(schema.extra2Placeholder ?? label, text: $extra2)
                    }
                }

                if let label = schema.notesLabel {
                    Section(label) {
                        TextField(schema.notesPlaceholder ?? label, text: $notes, axis: .vertical)
                            .lineLimit(3...8)
                    }
                }

                // Completion toggle (tasks & shopping)
                if let completionLabel = item?.completionLabel ?? (descriptor.key == "tasks" ? "Completed" : descriptor.key == "shopping" ? "Purchased" : nil) {
                    Section {
                        Toggle(completionLabel, isOn: $isCompleted)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(isEditing ? "Edit Item" : "Add \(descriptor.name) Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .keyboardShortcut(.return, modifiers: .command)
                }
            }
            .onAppear { loadExistingItem() }
            .frame(minWidth: 480, minHeight: 400)
        }
    }

    private func loadExistingItem() {
        guard let item else { return }
        title     = item.title
        subtitle  = item.subtitle ?? ""
        link      = item.link ?? ""
        extra1    = item.extra1 ?? ""
        extra2    = item.extra2 ?? ""
        notes     = item.notes ?? ""
        isCompleted = item.isCompleted
    }

    private func save() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        if let item {
            item.title = trimmedTitle
            item.subtitle = subtitle.isEmpty ? nil : subtitle
            item.link     = link.isEmpty ? nil : link
            item.extra1   = extra1.isEmpty ? nil : extra1
            item.extra2   = extra2.isEmpty ? nil : extra2
            item.notes    = notes.isEmpty ? nil : notes
            item.isCompleted = isCompleted
        } else {
            let newItem = CatalogItem(
                categoryKey: descriptor.key,
                title: trimmedTitle,
                subtitle: subtitle.isEmpty ? nil : subtitle,
                link:     link.isEmpty ? nil : link,
                extra1:   extra1.isEmpty ? nil : extra1,
                extra2:   extra2.isEmpty ? nil : extra2,
                notes:    notes.isEmpty ? nil : notes
            )
            newItem.isCompleted = isCompleted
            modelContext.insert(newItem)
        }

        try? modelContext.save()
        dismiss()
    }
}
