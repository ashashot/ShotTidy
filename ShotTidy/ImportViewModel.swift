//
//  ImportViewModel.swift
//  ShotTidy
//
//  ViewModel for importing and AI-analyzing screenshots.
//

import SwiftUI
import PhotosUI
import SwiftData

@Observable
@MainActor
final class ImportViewModel {

    // MARK: - Photos
    var selectedPickerItems: [PhotosPickerItem] = []
    var selectedImages: [UIImage] = []

    // MARK: - Analysis state
    var isAnalyzing = false
    var analysisError: String? = nil
    var progressCurrent = 0
    var progressTotal = 0
    /// Warnings (individual screenshot failures, non-fatal)
    var warnings: [String] = []

    // MARK: - Drafts (analysis result, pending confirmation)
    var draftItems: [DraftItem] = []

    // MARK: - SwiftData context (injected from View)
    var modelContext: ModelContext?

    /// IDs of Screenshots created in the current import session.
    /// Used to update or delete them after the user confirms (or cancels).
    private var sessionScreenshotIds: Set<UUID> = []
    /// Whether saveSelectedDrafts() was already called this session.
    private var didSaveThisSession = false

    // MARK: - Load images from PhotosPicker

    func loadSelectedImages() async {
        selectedImages = []
        for item in selectedPickerItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImages.append(image)
            }
        }
    }

    // MARK: - Analysis

    func analyzeImages() async {
        guard !selectedImages.isEmpty else { return }
        guard let ctx = modelContext else { return }

        isAnalyzing = true
        analysisError = nil
        warnings = []
        draftItems = []
        progressCurrent = 0
        progressTotal = selectedImages.count
        sessionScreenshotIds = []
        didSaveThisSession = false

        for (index, image) in selectedImages.enumerated() {
            progressCurrent = index + 1

            // Save the screenshot as a backup copy (provisional — may be deleted if not confirmed)
            let screenshot = Screenshot()
            screenshot.originalFileName = "screenshot_\(index + 1).jpg"
            screenshot.createdAt = Date()
            screenshot.analysisStatus = .analyzing

            let thumb = image.resized(toMaxDimension: 800)
            screenshot.thumbnailData = thumb.jpegData(compressionQuality: 0.85)

            ctx.insert(screenshot)
            try? ctx.save()

            // Track this screenshot for cleanup
            sessionScreenshotIds.insert(screenshot.id)

            do {
                let extracted = try await OpenAIAPIClient.shared.analyzeScreenshot(
                    image,
                    screenshotId: screenshot.id
                )

                draftItems.append(contentsOf: extracted)
                screenshot.analysisStatus = .done
                screenshot.analyzedAt = Date()
                screenshot.extractedItemsCount = extracted.count
            } catch let err as OpenAIError {
                screenshot.analysisStatus = .failed
                screenshot.errorMessage = err.localizedDescription

                switch err {
                case .refused, .emptyResponse:
                    // Refusal is non-fatal — just skip this screenshot
                    let name = screenshot.originalFileName ?? "screenshot \(index + 1)"
                    warnings.append("\(name): \(err.localizedDescription)")
                case .noAPIKey:
                    // Fatal — abort the entire analysis
                    analysisError = err.localizedDescription
                    isAnalyzing = false
                    try? ctx.save()
                    return
                default:
                    // Network / HTTP errors — only show if nothing was extracted
                    if draftItems.isEmpty && index == selectedImages.count - 1 {
                        analysisError = err.localizedDescription
                    }
                }
            } catch {
                screenshot.analysisStatus = .failed
                screenshot.errorMessage = error.localizedDescription
                if draftItems.isEmpty && index == selectedImages.count - 1 {
                    analysisError = error.localizedDescription
                }
            }

            try? ctx.save()
        }

        isAnalyzing = false
    }

    // MARK: - Save confirmed items

    func saveSelectedDrafts() {
        guard let ctx = modelContext else { return }
        let toSave = draftItems.filter { $0.isSelected && $0.isValid }

        // Count how many items were confirmed per screenshot
        var confirmedPerScreenshot: [UUID: Int] = [:]
        for draft in toSave {
            ctx.insert(draft.toCatalogItem())
            if let sid = draft.sourceScreenshotId {
                confirmedPerScreenshot[sid, default: 0] += 1
            }
        }

        // Update or delete session screenshots based on confirmed counts
        applySessionScreenshotChanges(confirmedCounts: confirmedPerScreenshot, context: ctx)

        didSaveThisSession = true
        try? ctx.save()
    }

    // MARK: - Reset

    func resetAfterConfirmation() {
        // If the user pressed Cancel (Save was never called), clean up all session screenshots.
        if !didSaveThisSession, let ctx = modelContext, !sessionScreenshotIds.isEmpty {
            applySessionScreenshotChanges(confirmedCounts: [:], context: ctx)
            try? ctx.save()
        }
        draftItems = []
        warnings = []
        sessionScreenshotIds = []
        didSaveThisSession = false
    }

    func fullReset() {
        selectedPickerItems = []
        selectedImages = []
        draftItems = []
        isAnalyzing = false
        analysisError = nil
        warnings = []
        progressCurrent = 0
        progressTotal = 0
        sessionScreenshotIds = []
        didSaveThisSession = false
    }

    // MARK: - Private helpers

    /// Updates or deletes session screenshots based on confirmed item counts.
    /// Screenshots with 0 confirmed items are deleted from the context.
    private func applySessionScreenshotChanges(confirmedCounts: [UUID: Int], context: ModelContext) {
        for screenshotId in sessionScreenshotIds {
            let count = confirmedCounts[screenshotId] ?? 0
            let sid = screenshotId
            let descriptor = FetchDescriptor<Screenshot>(
                predicate: #Predicate { $0.id == sid }
            )
            guard let screenshot = try? context.fetch(descriptor).first else { continue }

            if count == 0 {
                context.delete(screenshot)
            } else {
                screenshot.extractedItemsCount = count
            }
        }
        sessionScreenshotIds = []
    }
}
