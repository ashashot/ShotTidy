//
//  MacImportViewModel.swift
//  ShotTidierMac
//

import SwiftUI
import AppKit
import SwiftData

@Observable
@MainActor
final class MacImportViewModel {

    var selectedImages: [NSImage] = []
    var selectedURLs: [URL] = []

    var isAnalyzing = false
    var analysisError: String? = nil
    var persistenceError: String? = nil
    var progressCurrent = 0
    var progressTotal = 0
    var warnings: [String] = []

    var draftItems: [DraftItem] = []

    var modelContext: ModelContext?

    private var sessionScreenshotIds: Set<UUID> = []
    private var didSaveThisSession = false

    // MARK: - Analysis

    func analyzeImages(customCategories: [CategoryPromptInfo] = []) async {
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

            let screenshot = Screenshot()
            screenshot.originalFileName = selectedURLs.indices.contains(index)
                ? selectedURLs[index].lastPathComponent
                : "image_\(index + 1)"
            screenshot.createdAt = Date()
            screenshot.analysisStatus = .analyzing
            screenshot.thumbnailData = image.thumbnailData()

            ctx.insert(screenshot)
            saveCheckpoint(ctx)
            sessionScreenshotIds.insert(screenshot.id)

            do {
                let extracted = try await MacOpenAIAPIClient.shared.analyzeScreenshot(
                    image,
                    customCategories: customCategories,
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
                    let name = screenshot.originalFileName ?? "image \(index + 1)"
                    warnings.append("\(name): \(err.localizedDescription)")
                default:
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

            saveCheckpoint(ctx)
        }

        applyClipboardLink()
        isAnalyzing = false
    }

    // MARK: - Save confirmed items

    func saveSelectedDrafts() {
        guard let ctx = modelContext else { return }
        let toSave = draftItems.filter { $0.isSelected && $0.isValid && !$0.needsNewCategory }

        var confirmedPerScreenshot: [UUID: Int] = [:]
        for draft in toSave {
            ctx.insert(draft.toCatalogItem())
            if let sid = draft.sourceScreenshotId {
                confirmedPerScreenshot[sid, default: 0] += 1
            }
        }

        applySessionScreenshotChanges(confirmedCounts: confirmedPerScreenshot, context: ctx)
        didSaveThisSession = true
        saveCritical(ctx)
    }

    // MARK: - Clipboard link autofill

    private func applyClipboardLink() {
        let pb = NSPasteboard.general
        let urlString: String?
        if let urls = pb.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let url = urls.first {
            urlString = url.absoluteString
        } else if let str = pb.string(forType: .string),
                  let url = URL(string: str),
                  url.scheme == "https" || url.scheme == "http" {
            urlString = str
        } else {
            urlString = nil
        }
        guard let link = urlString, !link.isEmpty else { return }

        for i in draftItems.indices {
            guard let category = ItemCategory(rawValue: draftItems[i].categoryKey),
                  category.fieldSchema.linkLabel != nil,
                  !category.fieldSchema.isLinkEmail,
                  draftItems[i].link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { continue }
            draftItems[i].link = link
        }
    }

    // MARK: - Reset

    func resetAfterConfirmation() {
        if !didSaveThisSession, let ctx = modelContext, !sessionScreenshotIds.isEmpty {
            applySessionScreenshotChanges(confirmedCounts: [:], context: ctx)
            saveCheckpoint(ctx)
        }
        draftItems = []
        warnings = []
        sessionScreenshotIds = []
        didSaveThisSession = false
    }

    func fullReset() {
        if let ctx = modelContext, !sessionScreenshotIds.isEmpty {
            applySessionScreenshotChanges(confirmedCounts: [:], context: ctx)
            saveCheckpoint(ctx)
        }
        selectedImages = []
        selectedURLs = []
        draftItems = []
        isAnalyzing = false
        analysisError = nil
        persistenceError = nil
        warnings = []
        progressCurrent = 0
        progressTotal = 0
        sessionScreenshotIds = []
        didSaveThisSession = false
    }

    // MARK: - Persistence helpers

    private func saveCheckpoint(_ context: ModelContext) {
        try? context.save()
    }

    private func saveCritical(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            persistenceError = "Failed to save items: \(error.localizedDescription)"
        }
    }

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
