//
//  ShareAnalysisView.swift
//  ShotTidyShare
//
//  SwiftUI view shown inside the Share Extension.
//  Analyzes the shared image with GPT-4o and lets the user
//  confirm which items to save before closing.
//

import SwiftUI
import UIKit

// MARK: - View Model

@Observable
@MainActor
final class ShareAnalysisViewModel {

    // MARK: State

    enum Phase: Equatable {
        case extracting
        case analyzing
        case results
        case noItems
        case error(String)
        case saving
    }

    var phase: Phase = .extracting

    /// Wrapper keeps the draft item together with its selection state
    struct DraftWrapper: Identifiable {
        var id: UUID { item.id }
        var item: PendingDraftItem
        var isSelected: Bool = true
    }

    var draftWrappers: [DraftWrapper] = []

    var selectedCount: Int {
        draftWrappers.filter(\.isSelected).count
    }

    // MARK: Init

    private let inputItems: [NSExtensionItem]

    init(inputItems: [NSExtensionItem]) {
        self.inputItems = inputItems
    }

    // MARK: Start

    func start() async {
        // Step 1: extract image from share payload
        phase = .extracting
        guard let image = await extractImage(from: inputItems) else {
            phase = .error("Could not load the image from share data.")
            return
        }

        // Step 2: analyze via Supabase Edge Function (no local API key needed)
        phase = .analyzing
        do {
            let items = try await ShareAPIClient.shared.analyze(image: image)
            if items.isEmpty {
                phase = .noItems
            } else {
                draftWrappers = items.map { DraftWrapper(item: $0) }
                phase = .results
            }
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    // MARK: Save

    func saveSelected() throws {
        let selected = draftWrappers.filter(\.isSelected).map(\.item)
        try AppGroupManager.savePendingDrafts(selected)
        phase = .saving
    }

    // MARK: Image extraction

    private func extractImage(from extensionItems: [NSExtensionItem]) async -> UIImage? {
        for extensionItem in extensionItems {
            for provider in extensionItem.attachments ?? [] {
                let types = [
                    "public.jpeg", "public.png", "public.heic",
                    "public.tiff", "public.image", "com.compuserve.gif"
                ]
                guard let typeID = types.first(where: { provider.hasItemConformingToTypeIdentifier($0) }) else {
                    continue
                }
                if let image = await loadImage(from: provider, typeID: typeID) {
                    return image
                }
            }
        }
        return nil
    }

    private func loadImage(from provider: NSItemProvider, typeID: String) async -> UIImage? {
        await withCheckedContinuation { continuation in
            provider.loadDataRepresentation(forTypeIdentifier: typeID) { data, _ in
                guard let data, let image = UIImage(data: data) else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: image)
            }
        }
    }
}

// MARK: - View

struct ShareAnalysisView: View {
    @State private var viewModel: ShareAnalysisViewModel
    let onComplete: () -> Void
    let onCancel: () -> Void

    /// Identifies which item is being edited (index into viewModel.draftWrappers)
    private struct EditTarget: Identifiable {
        let index: Int
        var id: Int { index }
    }
    @State private var editTarget: EditTarget? = nil

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
                    do {
                        try viewModel.saveSelected()
                        // Brief pause so the user sees "Saving…" then the extension closes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            onComplete()
                        }
                    } catch {
                        // Fall back to just closing — items were not saved
                        onCancel()
                    }
                } label: {
                    Text(viewModel.selectedCount == 0
                         ? "Save"
                         : "Save (\(viewModel.selectedCount))")
                        .fontWeight(.semibold)
                }
                .disabled(viewModel.selectedCount == 0)
            }
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
        // Edit sheet
        .sheet(item: $editTarget) { target in
            ShareEditView(
                item: Binding(
                    get: { viewModel.draftWrappers[target.index].item },
                    set: { viewModel.draftWrappers[target.index].item = $0 }
                )
            )
        }
    }

    @ViewBuilder
    private func draftRow(index: Int) -> some View {
        let wrapper = viewModel.draftWrappers[index]
        let info = categoryDisplayInfo(for: wrapper.item.categoryKey)

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
                    Image(systemName: info.icon)
                        .font(.caption2)
                    Text(info.name)
                        .font(.caption2.weight(.semibold))
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

    // MARK: - Category display helpers

    private typealias CategoryInfo = (name: String, icon: String, color: Color)

    private func categoryDisplayInfo(for key: String) -> CategoryInfo {
        switch key {
        case "shopping":         return ("Shopping",          "cart.fill",               .orange)
        case "places":           return ("Places",            "mappin.circle.fill",       Color(red: 0.88, green: 0.18, blue: 0.18))
        case "appsServices":     return ("Apps & Services",   "app.fill",                 .blue)
        case "languageLearning": return ("Language Learning", "textformat.abc",            Color(red: 0.18, green: 0.75, blue: 0.35))
        case "prompts":          return ("Prompts",           "text.bubble.fill",         .purple)
        case "health":           return ("Health",            "heart.fill",               .pink)
        case "recipes":          return ("Recipes",           "fork.knife",               Color(red: 0.92, green: 0.67, blue: 0.12))
        case "books":            return ("Books",             "book.fill",                Color(red: 0.6, green: 0.38, blue: 0.18))
        case "movies":           return ("Movies & TV",       "play.rectangle.fill",      .indigo)
        case "quotes":           return ("Quotes",            "quote.bubble.fill",        .teal)
        case "articles":         return ("Articles",          "newspaper.fill",           Color(red: 0.0, green: 0.65, blue: 0.85))
        case "contacts":         return ("Contacts",          "person.circle.fill",       Color(red: 0.12, green: 0.72, blue: 0.72))
        case "tasks":            return ("Tasks",             "checkmark.circle.fill",    Color(red: 0.48, green: 0.48, blue: 0.56))
        default:                 return (key,                 "tag.fill",                 .gray)
        }
    }
}
