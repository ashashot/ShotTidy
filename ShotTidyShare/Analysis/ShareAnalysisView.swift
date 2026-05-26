//
//  ShareAnalysisView.swift
//  ShotTidyShare
//
//  Main SwiftUI view for the Share Extension.
//  Renders each phase: loading → results list → empty / error states.
//  Shows duplicate indicators for items already present in the catalog.
//

import SwiftUI

struct ShareAnalysisView: View {
    @State private var viewModel: ShareAnalysisViewModel
    let onComplete: () -> Void
    let onCancel: () -> Void

    /// Identifies which item is being edited (index into viewModel.draftWrappers)
    private struct EditTarget: Identifiable, Equatable {
        let index: Int
        var id: Int { index }
    }
    @State private var editTarget: EditTarget? = nil
    @State private var showDuplicateSaveAlert = false

    init(
        inputItems: [NSExtensionItem],
        onComplete: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: ShareAnalysisViewModel(inputItems: inputItems))
        self.onComplete = onComplete
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.phase {
                case .extracting:
                    loadingView(icon: "photo", text: "Loading image…")
                case .analyzing:
                    loadingView(icon: "sparkles", text: "Analyzing with GPT-4o…")
                case .results:
                    resultsView
                case .noItems:
                    emptyView
                case .error(let message):
                    errorView(message: message)
                case .saving:
                    loadingView(icon: "checkmark.circle", text: "Saving…")
                case .limitReached:
                    limitReachedView
                }
            }
            .navigationTitle("ShotTidy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
        }
        .task {
            await viewModel.start()
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // Cancel is always visible
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { onCancel() }
        }

        // Save button — only when results are shown
        if case .results = viewModel.phase {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    if viewModel.selectedDuplicateCount > 0 {
                        showDuplicateSaveAlert = true
                    } else {
                        performSave()
                    }
                } label: {
                    HStack(spacing: 4) {
                        if viewModel.selectedDuplicateCount > 0 {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                        }
                        Text(viewModel.selectedCount == 0
                             ? "Save"
                             : "Save (\(viewModel.selectedCount))")
                            .fontWeight(.semibold)
                    }
                }
                .disabled(viewModel.selectedCount == 0)
                .alert("Duplicate Items Found", isPresented: $showDuplicateSaveAlert) {
                    Button("Save Anyway") { performSave() }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    let count = viewModel.selectedDuplicateCount
                    Text(count == 1
                         ? "1 item may already exist in your catalog. Save anyway?"
                         : "\(count) items may already exist in your catalog. Save anyway?")
                }
            }
        }
    }

    // MARK: - Save

    private func performSave() {
        do {
            try viewModel.saveSelected()
            // Brief pause so the user sees "Saving…" then the extension closes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onComplete()
            }
        } catch {
            onCancel()
        }
    }

    // MARK: - Loading

    private func loadingView(icon: String, text: String) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(.systemFill))
                    .frame(width: 72, height: 72)
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            ProgressView()
                .scaleEffect(1.1)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results

    private var resultsView: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.blue)
                    Text("Tap ✏️ to edit an item before saving.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.blue.opacity(0.07))
            }

            ForEach(viewModel.draftWrappers.indices, id: \.self) { index in
                draftRow(index: index)
            }
        }
        .listStyle(.insetGrouped)
        // Edit sheet — .sheet(item:) guarantees atomic data passing
        .sheet(item: $editTarget) { target in
            ShareEditView(
                item: Binding(
                    get: { viewModel.draftWrappers[target.index].item },
                    set: { viewModel.draftWrappers[target.index].item = $0 }
                )
            )
        }
        // Re-check duplicates after editing (user may have changed the title)
        .onChange(of: editTarget) { _, newTarget in
            if newTarget == nil { viewModel.checkDuplicates() }
        }
    }

    @ViewBuilder
    private func draftRow(index: Int) -> some View {
        let wrapper = viewModel.draftWrappers[index]
        let info = ShareCategoryOption.displayInfo(for: wrapper.item.categoryKey)
        let dupLevel = wrapper.duplicateLevel

        HStack(spacing: 12) {
            // Checkbox
            Button {
                viewModel.draftWrappers[index].isSelected.toggle()
            } label: {
                Image(systemName: wrapper.isSelected
                      ? "checkmark.circle.fill"
                      : "circle")
                    .font(.title3)
                    .foregroundStyle(wrapper.isSelected ? .blue : Color(.systemFill))
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Category chip
                HStack(spacing: 4) {
                    Image(systemName: info.icon).font(.caption2)
                    Text(info.name).font(.caption2.weight(.semibold))
                }
                .foregroundStyle(info.color)

                // Title
                Text(wrapper.item.title)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(2)
                    .foregroundStyle(wrapper.isSelected ? .primary : .secondary)

                // Subtitle
                if !wrapper.item.subtitle.isEmpty {
                    Text(wrapper.item.subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                // Extra1
                if !wrapper.item.extra1.isEmpty {
                    Text(wrapper.item.extra1)
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }

                // Duplicate badge
                if let level = dupLevel {
                    Label(level.label, systemImage: level.icon)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(level.color)
                        .padding(.top, 1)
                }
            }

            Spacer(minLength: 0)

            // Edit button
            Button {
                editTarget = EditTarget(index: index)
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color(.systemFill))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .opacity(wrapper.isSelected ? 1.0 : 0.4)
        .listRowBackground(dupLevel == nil ? nil : Color.orange.opacity(0.07))
    }

    // MARK: - Empty

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 52))
                .foregroundStyle(.secondary)
            Text("Nothing Found")
                .font(.title3.weight(.semibold))
            Text("The screenshot didn't contain any recognizable catalog items.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Limit reached

    private var limitReachedView: some View {
        let usage  = ShareUsageManager.shared
        let limit  = ShareUsageManager.freeScreenshotsPerPeriod
        let resets = usage.periodEndDate

        return VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.12))
                    .frame(width: 88, height: 88)
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 38))
                    .foregroundStyle(.orange)
            }

            VStack(spacing: 8) {
                Text("Free Limit Reached")
                    .font(.title3.weight(.semibold))

                Text("You've used all \(limit) free screenshot analyses for this 30-day period.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // Reset countdown
                HStack(spacing: 4) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.caption)
                    Text("Resets on ")
                        .font(.caption)
                    Text(resets, style: .date)
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }

            // Upgrade hint
            VStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundStyle(.blue)
                Text("Open ShotTidy → Settings to upgrade to Pro for unlimited analyses.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.top, 8)

            Spacer()

            Button("Close") { onCancel() }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 52))
                .foregroundStyle(.orange)
            Text("Analysis Failed")
                .font(.title3.weight(.semibold))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
