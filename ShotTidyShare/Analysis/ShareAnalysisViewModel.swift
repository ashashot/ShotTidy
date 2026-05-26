//
//  ShareAnalysisViewModel.swift
//  ShotTidyShare
//
//  @Observable ViewModel for the Share Extension analysis flow.
//  Manages phases: extracting image → analyzing with GPT-4o → displaying results.
//

import SwiftUI
import UIKit

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

    /// Keeps a PendingDraftItem together with its selection state.
    struct DraftWrapper: Identifiable {
        var id: UUID { item.id }
        var item: PendingDraftItem
        var isSelected: Bool = true
    }

    // MARK: - State

    var phase: Phase = .extracting
    var draftWrappers: [DraftWrapper] = []

    var selectedCount: Int {
        draftWrappers.filter(\.isSelected).count
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
                phase = .results
            }
        } catch {
            phase = .error(error.localizedDescription)
        }
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
