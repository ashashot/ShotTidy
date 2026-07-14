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
        case .high:   return String(localized: "Likely duplicate", bundle: AppLocale.bundle)
        case .medium: return String(localized: "Possible duplicate", bundle: AppLocale.bundle)
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
        /// Brief "success" phase shown after analysis finds items, before .results.
        case complete(count: Int)
        case results
        /// AI returned no items, or analysis failed — user adds the item manually.
        case manualEntry
        case saving
        /// Free screenshot quota exhausted for the current 30-day period.
        case limitReached
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

    /// The image extracted from the share payload — retained for saving a Screenshot record.
    private var capturedImage: UIImage?

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
        // Step 0: check 30-day screenshot quota before making any API call
        let isPro = AppGroupManager.loadIsProStatus()
        let usage = ShareUsageManager.shared
        usage.performRollingReset(isPro: isPro)

        guard usage.canAnalyzeScreenshots(count: 1, isPro: isPro) else {
            phase = .limitReached
            return
        }

        // Step 1: extract image from share payload
        phase = .extracting
        guard let image = await extractImage(from: inputItems) else {
            phase = .manualEntry
            return
        }
        capturedImage = image

        // Step 2: analyze via Supabase Edge Function (no local API key needed)
        phase = .analyzing
        do {
            let items = try await ShareAPIClient.shared.analyze(image: image)
            if items.isEmpty {
                // Consume the quota slot even for "no items" — the API call was made
                usage.consumeScreenshots(count: 1)
                phase = .manualEntry
            } else {
                usage.consumeScreenshots(count: 1)
                draftWrappers = items.map { DraftWrapper(item: $0) }
                applyClipboardLink()    // Step 3: fill empty link fields from clipboard URL
                checkDuplicates()   // Step 4: mark items that already exist

                // Brief "success" screen before showing the results list
                phase = .complete(count: items.count)
                try? await Task.sleep(for: .milliseconds(650))
                phase = .results
            }
        } catch {
            // Network / server error — do NOT consume quota (no successful API call)
            phase = .manualEntry
        }
    }

    // MARK: - Clipboard link autofill

    /// Reads a URL from the clipboard and fills empty `link` fields on draft items
    /// whose category schema has a URL-type link field (non-email categories only).
    private func applyClipboardLink() {
        let pasteboard = UIPasteboard.general
        let urlString: String?
        if let url = pasteboard.url {
            urlString = url.absoluteString
        } else if let string = pasteboard.string,
                  let url = URL(string: string),
                  url.scheme == "https" || url.scheme == "http" {
            urlString = string
        } else {
            urlString = nil
        }
        guard let link = urlString, !link.isEmpty else { return }

        for i in draftWrappers.indices {
            let schema = ItemCategory.FieldSchema.resolved(for: draftWrappers[i].item.categoryKey)
            guard schema.linkLabel != nil,
                  !schema.isLinkEmail,
                  draftWrappers[i].item.link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { continue }
            draftWrappers[i].item.link = link
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

    // MARK: - Manual entry

    /// Called after the user fills in a draft manually.
    /// Adds it to draftWrappers and transitions to the results review screen.
    func commitManualDraft(_ draft: PendingDraftItem) {
        draftWrappers = [DraftWrapper(item: draft)]
        checkDuplicates()
        phase = .results
    }

    // MARK: - Save selected

    func saveSelected() throws {
        let selected = draftWrappers.filter(\.isSelected).map(\.item)
        try ShareCatalogWriter.save(selected, sourceImage: capturedImage)
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
