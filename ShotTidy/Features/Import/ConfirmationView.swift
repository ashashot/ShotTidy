//
//  ConfirmationView.swift
//  ShotTidy
//
//  Confirmation screen before saving extracted items.
//  The user can check/uncheck, edit, or delete each item.
//  Duplicate detection runs against the existing catalog on appear
//  and after every draft edit.
//

import SwiftUI
import SwiftData

/// An identifier wrapper for the index of the draft being edited.
/// Required for .sheet(item:) so SwiftUI passes data atomically
/// and does not build the sheet content before the index is set.
private struct DraftEditContext: Identifiable, Equatable {
    let id: Int  // global index in viewModel.draftItems
}

struct ConfirmationView: View {
    // @Bindable is needed to get bindings ($viewModel.draftItems[i])
    @Bindable var viewModel: ImportViewModel
    var onSaved: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var editingContext: DraftEditContext? = nil

    // MARK: - Duplicate detection
    @State private var draftDuplicates: [UUID: [DuplicateMatch]] = [:]
    @State private var showDuplicateSaveAlert = false

    // MARK: - Computed

    private var selectedCount: Int {
        viewModel.draftItems.filter { $0.isSelected && $0.isValid }.count
    }

    private var selectedDuplicateCount: Int {
        viewModel.draftItems.filter { draft in
            draft.isSelected && draft.isValid && !(draftDuplicates[draft.id] ?? []).isEmpty
        }.count
    }

    private var groupedItems: [(ItemCategory, [Int])] {
        ItemCategory.allCases.compactMap { category in
            let indices = viewModel.draftItems.indices.filter {
                viewModel.draftItems[$0].category == category
            }
            return indices.isEmpty ? nil : (category, indices)
        }
    }

    var body: some View {
        NavigationStack {
            listContent
                .navigationTitle("Confirmation")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbarContent }
                .sheet(item: $editingContext) { ctx in
                    DraftItemEditView(item: $viewModel.draftItems[ctx.id])
                }
                .onChange(of: editingContext) { _, newCtx in
                    if newCtx == nil { checkDuplicates() }
                }
                .alert("Duplicate Items Found", isPresented: $showDuplicateSaveAlert) {
                    Button("Save Anyway") { performSave() }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text(duplicateSaveAlertMessage)
                }
                .alert(
                    "Failed to Save",
                    isPresented: Binding(
                        get: { viewModel.persistenceError != nil },
                        set: { if !$0 { viewModel.persistenceError = nil } }
                    )
                ) {
                    Button("OK", role: .cancel) { viewModel.persistenceError = nil }
                } message: {
                    Text(viewModel.persistenceError ?? "An unexpected error occurred. Please try again.")
                }
                .onAppear { checkDuplicates() }
        }
    }

    // MARK: - List content

    @ViewBuilder
    private var listContent: some View {
        if viewModel.draftItems.isEmpty {
            ContentUnavailableView(
                "No Data",
                systemImage: "tray",
                description: Text("AI could not extract structured data from the screenshots")
            )
        } else {
            List {
                hintSection
                if !viewModel.warnings.isEmpty { warningsSection }
                categorySections
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Hint section

    private var hintSection: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill").foregroundStyle(.blue)
                Text("Review the data. Uncheck unnecessary items or tap ✏️ to edit.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .listRowBackground(Color.blue.opacity(0.07))
        }
    }

    // MARK: - Warnings section

    private var warningsSection: some View {
        Section {
            ForEach(viewModel.warnings, id: \.self) { warning in
                WarningRow(text: warning)
            }
            .listRowBackground(Color.orange.opacity(0.07))
        } header: {
            Text("Skipped (\(viewModel.warnings.count))").foregroundStyle(.orange)
        }
    }

    // MARK: - Category sections

    private var categorySections: some View {
        ForEach(groupedItems, id: \.0) { category, indices in
            Section {
                ForEach(indices, id: \.self) { index in
                    draftRow(at: index)
                }
                .onDelete { offsets in
                    deleteItems(offsets: offsets, globalIndices: indices)
                }
            } header: {
                categoryHeader(category, count: indices.count)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button {
                if selectedDuplicateCount > 0 {
                    showDuplicateSaveAlert = true
                } else {
                    performSave()
                }
            } label: {
                saveButtonLabel
            }
            .disabled(selectedCount == 0)
        }
    }

    private var saveButtonLabel: some View {
        HStack(spacing: 4) {
            if selectedDuplicateCount > 0 {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
            Text("Save (\(selectedCount))").fontWeight(.semibold)
        }
    }

    // MARK: - Draft row helper

    @ViewBuilder
    private func draftRow(at index: Int) -> some View {
        let draft = viewModel.draftItems[index]
        let dupes = draftDuplicates[draft.id] ?? []
        DraftItemRow(
            item: $viewModel.draftItems[index],
            duplicateMatches: dupes,
            onEdit: { editingContext = DraftEditContext(id: index) }
        )
        .listRowBackground(dupes.isEmpty ? nil : Color.orange.opacity(0.07))
    }

    // MARK: - Duplicate checking

    private func checkDuplicates() {
        var result: [UUID: [DuplicateMatch]] = [:]
        for draft in viewModel.draftItems where draft.isValid {
            let matches = DuplicateChecker.findDuplicates(
                for: draft.title,
                subtitle: draft.subtitle.isEmpty ? nil : draft.subtitle,
                link: draft.link.isEmpty ? nil : draft.link,
                category: draft.category,
                in: modelContext
            )
            if !matches.isEmpty {
                result[draft.id] = matches
            }
        }
        draftDuplicates = result
    }

    private var duplicateSaveAlertMessage: String {
        let count = selectedDuplicateCount
        return count == 1
            ? "1 item may already exist in your catalog. Save anyway?"
            : "\(count) items may already exist in your catalog. Save anyway?"
    }

    // MARK: - Save

    private func performSave() {
        viewModel.saveSelectedDrafts()
        if viewModel.persistenceError == nil { onSaved() }
    }

    // MARK: - Helpers

    private func categoryHeader(_ category: ItemCategory, count: Int) -> some View {
        HStack(spacing: 6) {
            Image(systemName: category.icon).foregroundStyle(category.color)
            Text(category.localizedName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer()
            Text("\(count)").font(.caption.bold()).foregroundStyle(category.color)
        }
    }

    private func deleteItems(offsets: IndexSet, globalIndices: [Int]) {
        let toRemove = offsets.map { globalIndices[$0] }.sorted(by: >)
        for gi in toRemove { viewModel.draftItems.remove(at: gi) }
    }
}

// MARK: - WarningRow

private struct WarningRow: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.caption)
                .padding(.top, 2)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - DraftItemRow

struct DraftItemRow: View {
    @Binding var item: DraftItem
    var duplicateMatches: [DuplicateMatch] = []
    let onEdit: () -> Void

    private var topDuplicate: DuplicateMatch? { duplicateMatches.first }

    var body: some View {
        HStack(spacing: 12) {
            checkboxButton
            contentStack
            Spacer()
            editButton
        }
        .padding(.vertical, 2)
        .opacity(item.isSelected ? 1.0 : 0.45)
    }

    private var checkboxButton: some View {
        Button {
            item.isSelected.toggle()
        } label: {
            Image(systemName: item.isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(item.isSelected ? .blue : Color(.systemFill))
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
    }

    private var contentStack: some View {
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
            if let match = topDuplicate {
                duplicateBadge(match)
            }
        }
    }

    private func duplicateBadge(_ match: DuplicateMatch) -> some View {
        Label(match.confidence.label, systemImage: match.confidence.icon)
            .font(.caption2.weight(.medium))
            .foregroundStyle(match.confidence.color)
            .padding(.top, 1)
    }

    private var editButton: some View {
        Button { onEdit() } label: {
            Image(systemName: "pencil.circle.fill")
                .font(.title3)
                .foregroundStyle(Color(.systemFill))
        }
        .buttonStyle(.plain)
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
                Section("Category") {
                    Picker("Category", selection: $item.category) {
                        ForEach(ItemCategory.allCases, id: \.self) { cat in
                            Label(cat.localizedName, systemImage: cat.icon).tag(cat)
                        }
                    }
                }

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
                    Button("Done") { dismiss() }.fontWeight(.semibold)
                }
            }
        }
    }
}
