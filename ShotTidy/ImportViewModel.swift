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

        for (index, image) in selectedImages.enumerated() {
            progressCurrent = index + 1

            // Save the screenshot as a backup copy
            let screenshot = Screenshot()
            screenshot.originalFileName = "screenshot_\(index + 1).jpg"
            screenshot.createdAt = Date()
            screenshot.analysisStatus = .analyzing

            let thumb = image.resized(toMaxDimension: 500)
            screenshot.thumbnailData = thumb.jpegData(compressionQuality: 0.8)

            ctx.insert(screenshot)
            try? ctx.save()

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
        // showConfirmation is removed from ViewModel — controlled via @State in ImportView
        // so the sheet opens exactly AFTER the async function completes, without a race condition
    }

    // MARK: - Save confirmed items

    func saveSelectedDrafts() {
        guard let ctx = modelContext else { return }
        let toSave = draftItems.filter { $0.isSelected && $0.isValid }
        for draft in toSave {
            ctx.insert(draft.toCatalogItem())
        }
        try? ctx.save()
        // Intentionally NOT calling resetAfterConfirmation() here.
        // Clearing draftItems happens in onDismiss of ImportView — AFTER the sheet
        // has fully animated closed and ConfirmationView is no longer rendering.
        // Calling reset here → draftItems = [] while ForEach is still active → index out of range.
    }

    // MARK: - Reset

    func resetAfterConfirmation() {
        draftItems = []
        warnings = []
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
    }
}
