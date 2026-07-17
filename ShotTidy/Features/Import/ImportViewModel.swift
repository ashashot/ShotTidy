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
    /// Non-nil when the server rejected every screenshot with a quota/rate-limit error (HTTP 429).
    /// Distinct from `analysisError` so the UI can route to the paywall instead of the generic
    /// "AI couldn't extract data, add manually" fallback — the client-side quota pre-check can be
    /// stale relative to the server's own limit, so this can fire even when the pre-check passed.
    var quotaExceededMessage: String? = nil
    /// Non-nil when a SwiftData save fails during confirmation — shown as an alert in the UI.
    var persistenceError: String? = nil
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
                // Downsize immediately so full-resolution images are never
                // retained in memory (the API size is 1024 anyway).
                selectedImages.append(image.resized(toMaxDimension: 1024))
            }
        }
    }

    // MARK: - Analysis

    func analyzeImages(
        customCategories: [CategoryPromptInfo] = [],
        allowNewCategory: Bool = false
    ) async {
        guard !selectedImages.isEmpty else { return }
        guard let ctx = modelContext else { return }

        isAnalyzing = true
        analysisError = nil
        quotaExceededMessage = nil
        warnings = []
        draftItems = []
        progressCurrent = 0
        progressTotal = selectedImages.count
        sessionScreenshotIds = []
        didSaveThisSession = false

        // Prepare all jobs up front. Each image is resized once to the API size;
        // the thumbnail is derived from that smaller image instead of the original.
        var jobs: [(index: Int, screenshot: Screenshot, image: UIImage)] = []
        for (index, image) in selectedImages.enumerated() {
            let apiImage = image.resized(toMaxDimension: 1024)

            // Save the screenshot as a backup copy (provisional — may be deleted if not confirmed)
            let screenshot = Screenshot()
            screenshot.originalFileName = "screenshot_\(index + 1).jpg"
            screenshot.createdAt = Date()
            screenshot.analysisStatus = .analyzing
            screenshot.thumbnailData = apiImage
                .resized(toMaxDimension: 800)
                .jpegData(compressionQuality: 0.85)

            ctx.insert(screenshot)
            // Track this screenshot for cleanup
            sessionScreenshotIds.insert(screenshot.id)
            jobs.append((index, screenshot, apiImage))
        }
        saveCheckpoint(ctx)

        // Analyze up to `maxConcurrent` screenshots in parallel. Drafts are
        // collected per index and appended in the original selection order.
        var collectedDrafts: [Int: [DraftItem]] = [:]
        var hardError: String? = nil

        await withTaskGroup(of: (Int, Result<[DraftItem], any Error>).self) { group in
            let maxConcurrent = 3
            var nextJob = 0

            func submitNext() {
                guard nextJob < jobs.count else { return }
                let job = jobs[nextJob]
                nextJob += 1
                let index = job.index
                let image = job.image
                let screenshotId = job.screenshot.id
                let imageLabel = job.screenshot.originalFileName ?? "screenshot_\(index + 1)"
                group.addTask {
                    do {
                        let extracted = try await OpenAIAPIClient.shared.analyzeScreenshot(
                            image,
                            customCategories: customCategories,
                            allowNewCategory: allowNewCategory,
                            screenshotId: screenshotId,
                            imageLabel: imageLabel
                        )
                        return (index, .success(extracted))
                    } catch {
                        return (index, .failure(error))
                    }
                }
            }

            for _ in 0..<min(maxConcurrent, jobs.count) { submitNext() }

            for await (index, result) in group {
                progressCurrent += 1
                let screenshot = jobs[index].screenshot

                switch result {
                case .success(let extracted):
                    collectedDrafts[index] = extracted
                    screenshot.analysisStatus = .done
                    screenshot.analyzedAt = Date()
                    screenshot.extractedItemsCount = extracted.count
                case .failure(let error):
                    screenshot.analysisStatus = .failed
                    screenshot.errorMessage = error.localizedDescription

                    if let err = error as? OpenAIError,
                       case .quotaExceeded = err {
                        // Server-side quota/rate limit — surfaced separately so the UI can
                        // route to the paywall instead of the "add manually" fallback.
                        quotaExceededMessage = err.localizedDescription
                    } else if let err = error as? OpenAIError,
                       case .refused = err {
                        // Refusal is non-fatal — just skip this screenshot
                        let name = screenshot.originalFileName ?? String(localized: "screenshot \(index + 1)", bundle: AppLocale.bundle)
                        warnings.append(String(localized: "\(name): \(err.localizedDescription)", bundle: AppLocale.bundle))
                    } else if let err = error as? OpenAIError,
                              case .emptyResponse = err {
                        let name = screenshot.originalFileName ?? String(localized: "screenshot \(index + 1)", bundle: AppLocale.bundle)
                        warnings.append(String(localized: "\(name): \(err.localizedDescription)", bundle: AppLocale.bundle))
                    } else {
                        // Network / HTTP errors — only shown if nothing was extracted
                        hardError = error.localizedDescription
                    }
                }

                saveCheckpoint(ctx)
                submitNext()
            }
        }

        draftItems = jobs.indices.compactMap { collectedDrafts[$0] }.flatMap { $0 }
        if draftItems.isEmpty, let hardError {
            analysisError = hardError
        }

        applyClipboardLink()
        isAnalyzing = false
    }

    // MARK: - Save confirmed items

    func saveSelectedDrafts() {
        guard let ctx = modelContext else { return }
        // Drafts still flagged as "needs new category" are skipped here — they are
        // resolved (assigned to a real category) before save in the confirmation flow.
        let toSave = draftItems.filter { $0.isSelected && $0.isValid && !$0.needsNewCategory }

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
        saveCritical(ctx)
    }

    // MARK: - Clipboard link autofill

    /// Reads a URL from the clipboard and fills empty `link` fields on draft items
    /// whose category schema has a URL-type link field (non-email categories only).
    /// Clears the clipboard after applying so subsequent imports don't reuse the same link.
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

        var applied = false
        for i in draftItems.indices {
            guard let category = ItemCategory(rawValue: draftItems[i].categoryKey),
                  category.fieldSchema.linkLabel != nil,
                  !category.fieldSchema.isLinkEmail,
                  draftItems[i].link.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { continue }
            draftItems[i].link = link
            applied = true
        }

        if applied {
            pasteboard.string = nil
        }
    }

    // MARK: - Reset

    func resetAfterConfirmation() {
        // If the user pressed Cancel (Save was never called), clean up all session screenshots.
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
        // If analysis created Screenshot records but the user closed without confirming,
        // delete those records from SwiftData to prevent orphaned entries.
        if let ctx = modelContext, !sessionScreenshotIds.isEmpty {
            applySessionScreenshotChanges(confirmedCounts: [:], context: ctx)
            saveCheckpoint(ctx)
        }
        selectedPickerItems = []
        selectedImages = []
        draftItems = []
        isAnalyzing = false
        analysisError = nil
        quotaExceededMessage = nil
        persistenceError = nil
        warnings = []
        progressCurrent = 0
        progressTotal = 0
        sessionScreenshotIds = []
        didSaveThisSession = false
    }

    // MARK: - Persistence helpers

    /// Non-critical save (intermediate progress). Logs failures but does not surface them to the user.
    private func saveCheckpoint(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            // checkpoint save failed — non-critical
        }
    }

    /// Critical save (user-confirmed items). Sets persistenceError so the UI can show an alert.
    private func saveCritical(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            persistenceError = String(localized: "Failed to save items: \(error.localizedDescription)", bundle: AppLocale.bundle)
        }
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
