//
//  MacConfirmationView.swift
//  ShotTidierMac
//
//  Confirmation step: review AI-extracted drafts before saving.
//

import SwiftUI
import SwiftData

struct MacConfirmationView: View {

    @Bindable var viewModel: MacImportViewModel
    var onSaved: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(CategoryStore.self) private var categoryStore

    @State private var editingIndex: Int? = nil

    // MARK: - New-category creation (from AI suggestion)
    @State private var newCategoryName: String? = nil

    private var selectedCount: Int {
        viewModel.draftItems.filter { $0.isSelected && $0.isValid && !$0.needsNewCategory }.count
    }

    private var groupedItems: [(CategoryDescriptor, [Int])] {
        let allDescriptors = categoryStore.allDescriptors
        return allDescriptors.compactMap { descriptor in
            let indices = viewModel.draftItems.indices.filter {
                viewModel.draftItems[$0].categoryKey == descriptor.key
            }
            return indices.isEmpty ? nil : (descriptor, indices)
        }
    }

    /// Drafts the AI could not fit into any existing category ("__new__").
    private var newCategoryIndices: [Int] {
        viewModel.draftItems.indices.filter { viewModel.draftItems[$0].needsNewCategory }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.draftItems.isEmpty {
                    emptyView
                } else {
                    List {
                        ForEach(groupedItems, id: \.0) { descriptor, indices in
                            Section {
                                ForEach(indices, id: \.self) { index in
                                    DraftItemRow(
                                        draft: $viewModel.draftItems[index],
                                        schema: descriptor.fieldSchema,
                                        onEdit: { editingIndex = index }
                                    )
                                }
                            } header: {
                                HStack(spacing: 6) {
                                    Image(systemName: descriptor.iconName)
                                        .foregroundStyle(descriptor.color)
                                    Text(descriptor.name)
                                        .fontWeight(.semibold)
                                }
                            }
                        }

                        if !newCategoryIndices.isEmpty {
                            Section {
                                ForEach(newCategoryIndices, id: \.self) { index in
                                    DraftItemRow(
                                        draft: $viewModel.draftItems[index],
                                        schema: CategoryDescriptor.unresolved(key: DraftItem.newCategoryKey).fieldSchema,
                                        onEdit: { editingIndex = index },
                                        onCreateCategory: {
                                            let name = viewModel.draftItems[index].suggestedCategoryName
                                            if !name.isEmpty { newCategoryName = name }
                                        }
                                    )
                                }
                            } header: {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .foregroundStyle(.purple)
                                    Text("Suggested New Categories")
                                        .fontWeight(.semibold)
                                }
                            } footer: {
                                Text("Create the suggested category to include these items in the save.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .listStyle(.inset)

                    Divider()

                    if !viewModel.warnings.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(viewModel.warnings, id: \.self) { warning in
                                Label(warning, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.orange.opacity(0.06))
                    }

                    HStack(spacing: 12) {
                        Button("Select All") {
                            for i in viewModel.draftItems.indices {
                                viewModel.draftItems[i].isSelected = true
                            }
                        }
                        Button("Deselect All") {
                            for i in viewModel.draftItems.indices {
                                viewModel.draftItems[i].isSelected = false
                            }
                        }
                        Spacer()
                        Text("\(selectedCount) item\(selectedCount == 1 ? "" : "s") selected")
                            .foregroundStyle(.secondary)
                        Button("Cancel") {
                            dismiss()
                        }
                        Button("Save \(selectedCount > 0 ? "\(selectedCount) Item\(selectedCount == 1 ? "" : "s")" : "")") {
                            viewModel.saveSelectedDrafts()
                            onSaved()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedCount == 0)
                        .keyboardShortcut(.return, modifiers: .command)
                    }
                    .padding()
                }
            }
            .navigationTitle("Review \(viewModel.draftItems.count) Extracted Item\(viewModel.draftItems.count == 1 ? "" : "s")")
            .frame(minWidth: 600, minHeight: 400)
            .sheet(item: Binding(
                get: { editingIndex.map { DraftEditID(index: $0) } },
                set: { editingIndex = $0?.index }
            )) { editID in
                MacDraftEditView(draft: $viewModel.draftItems[editID.index])
            }
            .sheet(item: Binding(
                get: { newCategoryName.map { NewCategoryContext(name: $0) } },
                set: { newCategoryName = $0?.name }
            )) { ctx in
                MacCategoryEditorView(prefillName: ctx.name) { newKey in
                    assignDraftsWithSuggestion(named: ctx.name, toKey: newKey)
                }
            }
        }
    }

    // MARK: - New-category assignment

    /// After a category is created from a suggestion, reassign every draft that
    /// carried that suggested name to the new category key.
    private func assignDraftsWithSuggestion(named name: String, toKey key: String) {
        let target = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for i in viewModel.draftItems.indices {
            let draft = viewModel.draftItems[i]
            guard draft.needsNewCategory,
                  draft.suggestedCategoryName.trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased() == target
            else { continue }
            viewModel.draftItems[i].categoryKey = key
            viewModel.draftItems[i].suggestedCategoryName = ""
        }
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Items Found",
            systemImage: "tray",
            description: Text("The AI could not extract any items from the selected images.")
        )
    }
}

// MARK: - DraftEditID

private struct DraftEditID: Identifiable {
    let index: Int
    var id: Int { index }
}

// MARK: - NewCategoryContext

private struct NewCategoryContext: Identifiable {
    let name: String
    var id: String { name }
}

// MARK: - DraftItemRow

private struct DraftItemRow: View {
    @Binding var draft: DraftItem
    let schema: ItemCategory.FieldSchema
    let onEdit: () -> Void
    var onCreateCategory: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $draft.isSelected)
                .labelsHidden()
                .toggleStyle(.checkbox)

            VStack(alignment: .leading, spacing: 2) {
                Text(draft.displayTitle)
                    .font(.headline)
                    .lineLimit(1)
                if !draft.subtitle.isEmpty {
                    Text(draft.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if !draft.link.isEmpty {
                    Text(draft.link)
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .lineLimit(1)
                }
                if draft.needsNewCategory && !draft.suggestedCategoryName.isEmpty {
                    Label("New: \(draft.suggestedCategoryName)", systemImage: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
            }

            Spacer()

            if let onCreateCategory {
                Button("Create Category") { onCreateCategory() }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundStyle(.purple)
            }

            Button("Edit") { onEdit() }
                .buttonStyle(.borderless)
                .font(.caption)
        }
        .padding(.vertical, 2)
        .opacity(draft.isSelected ? 1.0 : 0.5)
    }
}

// MARK: - MacDraftEditView

struct MacDraftEditView: View {
    @Binding var draft: DraftItem
    @Environment(\.dismiss) private var dismiss

    private var schema: ItemCategory.FieldSchema {
        (ItemCategory(rawValue: draft.categoryKey) ?? .tasks).fieldSchema
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    Picker("Category", selection: $draft.categoryKey) {
                        ForEach(ItemCategory.allCases, id: \.rawValue) { cat in
                            Label(cat.localizedName, systemImage: cat.icon).tag(cat.rawValue)
                        }
                    }
                }

                Section(schema.titleLabel) {
                    TextField(schema.titlePlaceholder, text: $draft.title, axis: .vertical)
                        .lineLimit(1...3)
                }

                if let label = schema.subtitleLabel {
                    Section(label) {
                        TextField(schema.subtitlePlaceholder ?? label, text: $draft.subtitle, axis: .vertical)
                            .lineLimit(1...3)
                    }
                }

                if let label = schema.linkLabel {
                    Section(label) {
                        TextField(schema.linkPlaceholder ?? "https://...", text: $draft.link)
                    }
                }

                if let label = schema.extra1Label {
                    Section(label) {
                        TextField(schema.extra1Placeholder ?? label, text: $draft.extra1)
                    }
                }

                if let label = schema.extra2Label {
                    Section(label) {
                        TextField(schema.extra2Placeholder ?? label, text: $draft.extra2)
                    }
                }

                if let label = schema.notesLabel {
                    Section(label) {
                        TextField(schema.notesPlaceholder ?? label, text: $draft.notes, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Edit Item")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .frame(minWidth: 480, minHeight: 400)
        }
    }
}
