//
//  ShareAnalysisViewModel.swift
//  ShotTidyShare
//
//  @Observable ViewModel for the Share Extension analysis flow.
//  Manages phases: extracting image → analyzing with GPT-4o → displaying results.
//  After analysis, checks for duplicates against the catalog index written by the main app.
//

import SwiftUI
import UIKit

// MARK: - Duplicate level

/// Confidence level of a duplicate match found in the catalog index.
enum ShareDuplicateLevel {
    /// Title matches only (case-insensitive).
    case medium
    /// Title + subtitle or title + link also match.
    case high

    var label: String {
        switch self {
        case .high:   return "Likely duplicate"
        case .medium: return "Possible duplicate"
        }
    }

    var icon: String {
        switch self {
        case .high:   return "exclamationmark.2.circle.fill"
        case .medium: return "exclamationmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .high:   return .red
        case .medium: return .orange
        }
    }
}

// MARK: - ViewModel

@Observable
@MainActor
final class ShareAnalysisViewModel {

    // MARK: - Phase

    enum Phase: Equatable {
        case extracting
        case analyzing
        case results
        case noItems
        case error(String)
        case saving
    }

    // MARK: - Draft Wrapper

    /// Keeps a PendingDraftItem together with its selection state and duplicate info.
    struct DraftWrapper: Identifiable {
        var id: UUID { item.id }
        var item: PendingDraftItem
        var isSelected: Bool = true
        /// Non-nil if a matching item was found in the catalog index.
        var duplicateLevel: ShareDuplicateLevel? = nil
    }

    // MARK: - State

    var phase: Phase = .extracting
    var draftWrappers: [DraftWrapper] = []

    var selectedCount: Int {
        draftWrappers.filter(\.isSelected).count
    }

    /// Number of selected items that have a duplicate match.
    var selectedDuplicateCount: Int {
        draftWrappers.filter { $0.isSelected && $0.duplicateLevel != nil }.count
    }

    // MARK: - Init

    private let inputItems: [NSExtensionItem]

    init(inputItems: [NSExtensionItem]) {
        self.inputItems = inputItems
    }

    // MARK: - Start analysis

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
                checkDuplicates()   // Step 3: mark items that already exist
                phase = .results
            }
        } catch {
            phase = .error(error.localizedDescription)
        }
    }

    // MARK: - Duplicate detection

    /// Loads the catalog index written by the main app and marks each draft
    /// that already exists in the catalog with the appropriate duplicate level.
    func checkDuplicates() {
        let index = AppGroupManager.loadCatalogIndex()
        guard !index.isEmpty else { return }

        for i in draftWrappers.indices {
            draftWrappers[i].duplicateLevel = findDuplicateLevel(
                for: draftWrappers[i].item,
                in: index
            )
        }
    }

    private func findDuplicateLevel(
        for draft: PendingDraftItem,
        in index: [CatalogIndexEntry]
    ) -> ShareDuplicateLevel? {

        let normalizedTitle = draft.title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalizedTitle.isEmpty else { return nil }

        for entry in index {
            // Only compare within the same category
            guard entry.categoryKey == draft.categoryKey else { continue }

            let entryTitle = entry.title
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            guard entryTitle == normalizedTitle else { continue }

            // Title matched — check subtitle and link for confidence boost
            let normalizedSub = draft.subtitle
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            let entrySub = entry.subtitle?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if let es = entrySub, !normalizedSub.isEmpty, !es.isEmpty, es == normalizedSub {
                return .high
            }

            let normalizedLink = draft.link
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            let entryLink = entry.link?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if let el = entryLink, !normalizedLink.isEmpty, !el.isEmpty, el == normalizedLink {
                return .high
            }

            return .medium
        }

        return nil
    }

    // MARK: - Save selected

    func saveSelected() throws {
        let selected = draftWrappers.filter(\.isSelected).map(\.item)
        try AppGroupManager.savePendingDrafts(selected)
        phase = .saving
    }

    // MARK: - Image extraction

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
