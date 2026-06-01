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

/// Identifiable wrapper for presenting the new-category editor by suggested name.
private struct NewCategoryContext: Identifiable, Equatable {
    let name: String
    var id: String { name }
}

struct ConfirmationView: View {
    // @Bindable is needed to get bindings ($viewModel.draftItems[i])
    @Bindable var viewModel: ImportViewModel
    var onSaved: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(CategoryStore.self) private var categoryStore

    @State private var editingContext: DraftEditContext? = nil

    // MARK: - New-category creation (from AI suggestion)
    @State private var newCategoryName: String? = nil

    // MARK: - Duplicate detection
    @State private var draftDuplicates: [UUID: [DuplicateMatch]] = [:]
    @State private var showDuplicateSaveAlert = false

    // MARK: - Computed

    private var selectedCount: Int {
        viewModel.draftItems.filter { $0.isSelected && $0.isValid && !$0.needsNewCategory }.count
    }

    private var selectedDuplicateCount: Int {
        viewModel.draftItems.filter { draft in
            draft.isSelected && draft.isValid && !(draftDuplicates[draft.id] ?? []).isEmpty
        }.count
    }

    /// Distinct category keys present in the drafts, in display order
    /// (built-in first, then custom, then the "new category" bucket last).
    private var groupedItems: [(String, [Int])] {
        var orderedKeys: [String] = categoryStore.allDescriptors.map(\.key)
        orderedKeys.append(DraftItem.newCategoryKey)

        return orderedKeys.compactMap { key in
            let indices = viewModel.draftItems.indices.filter {
                viewModel.draftItems[$0].categoryKey == key
            }
            return indices.isEmpty ? nil : (key, indices)
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
                .sheet(item: Binding(
                    get: { newCategoryName.map { NewCategoryContext(name: $0) } },
                    set: { newCategoryName = $0?.name }
                )) { ctx in
                    CategoryEditorView(prefillName: ctx.name) { newKey in
                        assignDraftsWithSuggestion(named: ctx.name, toKey: newKey)
                    }
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
        ForEach(groupedItems, id: \.0) { categoryKey, indices in
            Section {
                ForEach(indices, id: \.self) { index in
                    draftRow(at: index)
                }
                .onDelete { offsets in
                    deleteItems(offsets: offsets, globalIndices: indices)
                }
            } header: {
                categoryHeader(categoryKey, count: indices.count)
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
            onEdit: { editingContext = DraftEditContext(id: index) },
            onCreateCategory: draft.needsNewCategory && !draft.suggestedCategoryName.isEmpty
                ? { newCategoryName = draft.suggestedCategoryName }
                : nil
        )
        .listRowBackground(
            draft.needsNewCategory
                ? Color.purple.opacity(0.07)
                : (dupes.isEmpty ? nil : Color.orange.opacity(0.07))
        )
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
        checkDuplicates()
    }

    // MARK: - Duplicate checking

    private func checkDuplicates() {
        var result: [UUID: [DuplicateMatch]] = [:]
        for draft in viewModel.draftItems where draft.isValid && !draft.needsNewCategory {
            let matches = DuplicateChecker.findDuplicates(
                for: draft.title,
                subtitle: draft.subtitle.isEmpty ? nil : draft.subtitle,
                link: draft.link.isEmpty ? nil : draft.link,
                categoryKey: draft.categoryKey,
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

    @ViewBuilder
    private func categoryHeader(_ categoryKey: String, count: Int) -> some View {
        if categoryKey == DraftItem.newCategoryKey {
            HStack(spacing: 6) {
                Image(systemName: "sparkles").foregroundStyle(.purple)
                Text("Suggested New Categories")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(count)").font(.caption.bold()).foregroundStyle(.purple)
            }
        } else {
            let descriptor = categoryStore.descriptor(forKey: categoryKey)
            HStack(spacing: 6) {
                Image(systemName: descriptor.iconName).foregroundStyle(descriptor.color)
                Text(descriptor.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(count)").font(.caption.bold()).foregroundStyle(descriptor.color)
            }
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
    /// Present when this draft suggests a new category that can be created.
    var onCreateCategory: (() -> Void)? = nil

    private var topDuplicate: DuplicateMatch? { duplicateMatches.first }

    var body: some View {
        HStack(spacing: 12) {
            checkboxButton
            contentStack
            Spacer()
            if let onCreateCategory {
                createCategoryButton(onCreateCategory)
            }
            editButton
        }
        .padding(.vertical, 2)
        .opacity(item.isSelected ? 1.0 : 0.45)
    }

    private func createCategoryButton(_ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: "folder.badge.plus")
                .font(.title3)
                .foregroundStyle(.purple)
        }
        .buttonStyle(.plain)
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
            if item.needsNewCategory && !item.suggestedCategoryName.isEmpty {
                Label("New: \(item.suggestedCategoryName)", systemImage: "sparkles")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.purple)
                    .padding(.top, 1)
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
    @Environment(CategoryStore.self) private var categoryStore

    @State private var enrichState: DraftEnrichState = .idle
    @State private var highlightedFields: Set<String> = []

    /// Resolved descriptor for the draft's current category key.
    /// Falls back to the generic schema for `__new__` drafts.
    private var descriptor: CategoryDescriptor {
        item.needsNewCategory
            ? .unresolved(key: DraftItem.newCategoryKey)
            : categoryStore.descriptor(forKey: item.categoryKey)
    }
    private var schema: ItemCategory.FieldSchema { descriptor.fieldSchema }

    /// True when title is set and at least one schema-defined optional field is empty.
    private var hasMissingFields: Bool {
        guard !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        let checks: [(label: String?, value: String)] = [
            (schema.subtitleLabel, item.subtitle),
            (schema.linkLabel,     item.link),
            (schema.extra1Label,   item.extra1),
            (schema.extra2Label,   item.extra2),
            (schema.notesLabel,    item.notes),
        ]
        return checks.contains { label, value in
            label != nil && value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    if item.needsNewCategory {
                        Label("New category suggested: \(item.suggestedCategoryName)",
                              systemImage: "sparkles")
                            .foregroundStyle(.purple)
                    }
                    Picker("Category", selection: $item.categoryKey) {
                        if item.needsNewCategory {
                            Label("Suggested: \(item.suggestedCategoryName)",
                                  systemImage: "sparkles")
                                .tag(DraftItem.newCategoryKey)
                        }
                        ForEach(categoryStore.allDescriptors) { desc in
                            Label(desc.name, systemImage: desc.iconName).tag(desc.key)
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
                            .listRowBackground(
                                highlightedFields.contains("subtitle") ? Color.green.opacity(0.15) : nil
                            )
                    }
                }

                if let label = schema.linkLabel {
                    Section(label) {
                        TextField(schema.linkPlaceholder ?? "https://...", text: $item.link)
                            .keyboardType(schema.isLinkEmail ? .emailAddress : .URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .listRowBackground(
                                highlightedFields.contains("link") ? Color.green.opacity(0.15) : nil
                            )
                    }
                }

                if let label = schema.extra1Label {
                    Section(label) {
                        TextField(schema.extra1Placeholder ?? "", text: $item.extra1)
                            .listRowBackground(
                                highlightedFields.contains("extra1") ? Color.green.opacity(0.15) : nil
                            )
                    }
                }

                if let label = schema.extra2Label {
                    Section(label) {
                        TextField(schema.extra2Placeholder ?? "", text: $item.extra2)
                            .listRowBackground(
                                highlightedFields.contains("extra2") ? Color.green.opacity(0.15) : nil
                            )
                    }
                }

                if let label = schema.notesLabel {
                    Section(label) {
                        TextField(schema.notesPlaceholder ?? label, text: $item.notes, axis: .vertical)
                            .lineLimit(6, reservesSpace: false)
                            .listRowBackground(
                                highlightedFields.contains("notes") ? Color.green.opacity(0.15) : nil
                            )
                    }
                }
            }
            // Status bar — shown only while search is active (loading / success / error)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if enrichState != .idle {
                    draftEnrichStatusBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3), value: enrichState == .idle)
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Done — top LEFT
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
                // Search — top RIGHT, shown only when fields are missing and not already searching
                ToolbarItem(placement: .topBarTrailing) {
                    if hasMissingFields && enrichState == .idle {
                        Button(action: runEnrichment) {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(descriptor.color)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Status bar (bottom, shown only during active search)

    @ViewBuilder
    private var draftEnrichStatusBar: some View {
        let color = descriptor.color
        VStack(spacing: 0) {
            Divider()
            Group {
                switch enrichState {
                case .idle:
                    EmptyView()

                case .loading:
                    HStack(spacing: 12) {
                        ProgressView().tint(color)
                        Text("Searching the web…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)

                case .success(let count):
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text(count == 1
                             ? "1 field filled — review and tap Done"
                             : "\(count) fields filled — review and tap Done")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)

                case .failure(let message):
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        Spacer()
                        Button("Retry") { withAnimation { enrichState = .idle } }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(color)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
            }
            .background(.bar)
        }
    }

    // MARK: - Enrichment logic

    private func runEnrichment() {
        withAnimation { enrichState = .loading }
        highlightedFields = []

        Task {
            do {
                let result = try await EnrichmentAPIClient.shared.enrichFields(
                    categoryKey: item.categoryKey,
                    title: item.title,
                    subtitle: item.subtitle,
                    link: item.link,
                    extra1: item.extra1,
                    extra2: item.extra2,
                    notes: item.notes,
                    schema: schema
                )

                var filled = 0
                var keys = Set<String>()

                if let v = result.subtitle, item.subtitle.isEmpty { item.subtitle = v; filled += 1; keys.insert("subtitle") }
                if let v = result.link,     item.link.isEmpty     { item.link     = v; filled += 1; keys.insert("link") }
                if let v = result.extra1,   item.extra1.isEmpty   { item.extra1   = v; filled += 1; keys.insert("extra1") }
                if let v = result.extra2,   item.extra2.isEmpty   { item.extra2   = v; filled += 1; keys.insert("extra2") }
                if let v = result.notes,    item.notes.isEmpty    { item.notes    = v; filled += 1; keys.insert("notes") }

                withAnimation(.spring(duration: 0.35)) {
                    highlightedFields = keys
                    enrichState = filled > 0 ? .success(filled) : .failure("No additional info found.")
                }

                Task {
                    try? await Task.sleep(for: .seconds(4))
                    withAnimation(.easeOut(duration: 0.6)) { highlightedFields = [] }
                }

            } catch {
                withAnimation { enrichState = .failure(error.localizedDescription) }
            }
        }
    }
}

// MARK: - DraftEnrichState

private enum DraftEnrichState: Equatable {
    case idle
    case loading
    case success(Int)
    case failure(String)
}
