//
//  ConfirmationView.swift
//  ShotTidy
//
//  Confirmation screen before saving extracted items.
//  The user can check/uncheck, edit, or delete each item.
//

import SwiftUI

/// An identifier wrapper for the index of the draft being edited.
/// Required for .sheet(item:) so SwiftUI passes data atomically
/// and does not build the sheet content before the index is set.
private struct DraftEditContext: Identifiable {
    let id: Int  // global index in viewModel.draftItems
}

struct ConfirmationView: View {
    // @Bindable is needed to get bindings ($viewModel.draftItems[i])
    @Bindable var viewModel: ImportViewModel
    var onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss
    /// Edit context: set → sheet opens → reset on close.
    /// Single source of truth: .sheet(item:) guarantees that content is built
    /// only when editingContext != nil, eliminating race conditions.
    @State private var editingContext: DraftEditContext? = nil

    private var selectedCount: Int {
        viewModel.draftItems.filter { $0.isSelected && $0.isValid }.count
    }

    // Grouping: list of (category, [global indices in draftItems])
    private var groupedItems: [(ItemCategory, [Int])] {
        ItemCategory.allCases.compactMap { category in
            let indices = viewModel.draftItems.indices.filter { i in
                viewModel.draftItems[i].category == category
            }
            return indices.isEmpty ? nil : (category, indices)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.draftItems.isEmpty {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "tray",
                        description: Text("AI could not extract structured data from the screenshots")
                    )
                } else {
                    List {
                        // Hint
                        Section {
                            HStack(spacing: 10) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundStyle(.blue)
                                Text("Review the data. Uncheck unnecessary items or tap ✏️ to edit.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .listRowBackground(Color.blue.opacity(0.07))
                        }

                        // Warnings (skipped screenshots)
                        if !viewModel.warnings.isEmpty {
                            Section {
                                ForEach(viewModel.warnings, id: \.self) { warning in
                                    HStack(alignment: .top, spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(.orange)
                                            .font(.caption)
                                            .padding(.top, 2)
                                        Text(warning)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .listRowBackground(Color.orange.opacity(0.07))
                            } header: {
                                Text("Skipped (\(viewModel.warnings.count))")
                                    .foregroundStyle(.orange)
                            }
                        }

                        // Groups by category
                        ForEach(groupedItems, id: \.0) { category, indices in
                            Section {
                                ForEach(indices, id: \.self) { index in
                                    DraftItemRow(
                                        item: $viewModel.draftItems[index],
                                        onEdit: {
                                            // Single step → sheet opens only
                                            // when item != nil, without a race condition
                                            editingContext = DraftEditContext(id: index)
                                        }
                                    )
                                }
                                .onDelete { offsets in
                                    deleteItems(offsets: offsets, globalIndices: indices)
                                }
                            } header: {
                                categoryHeader(category, count: indices.count)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Confirmation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        viewModel.saveSelectedDrafts()
                        onSaved()
                    } label: {
                        Text("Save (\(selectedCount))")
                            .fontWeight(.semibold)
                    }
                    .disabled(selectedCount == 0)
                }
            }
            // Edit sheet.
            // .sheet(item:) guarantees atomicity: SwiftUI builds DraftItemEditView
            // only when editingContext != nil, and automatically resets it to nil
            // on close — no extra flag needed and no race condition.
            .sheet(item: $editingContext) { ctx in
                DraftItemEditView(item: $viewModel.draftItems[ctx.id])
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func categoryHeader(_ category: ItemCategory, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon)
                .foregroundStyle(category.color)
            Text(category.localizedName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            Text("\(count)")
                .font(.caption.bold())
                .foregroundStyle(category.color)
        }
    }

    private func deleteItems(offsets: IndexSet, globalIndices: [Int]) {
        // Convert local offsets to global indices, remove from the end
        let toRemove = offsets
            .map { localOffset in globalIndices[localOffset] }
            .sorted(by: >)
        for gi in toRemove {
            viewModel.draftItems.remove(at: gi)
        }
    }
}

// MARK: - DraftItemRow

struct DraftItemRow: View {
    @Binding var item: DraftItem
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                item.isSelected.toggle()
            } label: {
                Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isSelected ? .blue : Color(.systemFill))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 3) {
                Text(item.displayTitle)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(2)
                    .foregroundStyle(item.isSelected ? .primary : .secondary)

                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                if !item.extra1.isEmpty {
                    Text(item.extra1)
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Edit button
            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color(.systemFill))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .opacity(item.isSelected ? 1.0 : 0.45)
    }
}

// MARK: - DraftItemEditView

struct DraftItemEditView: View {
    @Binding var item: DraftItem
    @Environment(\.dismiss) private var dismiss

    private var schema: ItemCategory.FieldSchema { item.category.fieldSchema }

    var body: some View {
        NavigationStack {
            Form {
                // Category picker
                Section("Category") {
                    Picker("Category", selection: $item.category) {
                        ForEach(ItemCategory.allCases, id: \.self) { cat in
                            Label(cat.localizedName, systemImage: cat.icon).tag(cat)
                        }
                    }
                }

                // Main fields
                Section(schema.titleLabel) {
                    TextField(schema.titlePlaceholder, text: $item.title, axis: .vertical)
                        .lineLimit(4, reservesSpace: false)
                }

                if let label = schema.subtitleLabel {
                    Section(label) {
                        TextField(schema.subtitlePlaceholder ?? "", text: $item.subtitle, axis: .vertical)
                            .lineLimit(3, reservesSpace: false)
                    }
                }

                if let label = schema.linkLabel {
                    Section(label) {
                        TextField(schema.linkPlaceholder ?? "https://...", text: $item.link)
                            .keyboardType(schema.isLinkEmail ? .emailAddress : .URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }

                if let label = schema.extra1Label {
                    Section(label) {
                        TextField(schema.extra1Placeholder ?? "", text: $item.extra1)
                    }
                }

                if let label = schema.extra2Label {
                    Section(label) {
                        TextField(schema.extra2Placeholder ?? "", text: $item.extra2)
                    }
                }

                if let label = schema.notesLabel {
                    Section(label) {
                        TextField(schema.notesPlaceholder ?? label, text: $item.notes, axis: .vertical)
                            .lineLimit(6, reservesSpace: false)
                    }
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
