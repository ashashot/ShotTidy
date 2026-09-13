//
//  MacScreenshotAnalysisService.swift
//  ShotTidierMac
//
//  macOS counterpart of the iOS `ScreenshotAnalysisService`: dispatches one
//  screenshot to the engine picked by `AnalysisEngineResolver` and maps the
//  on-device engine's raw items into `DraftItem`s. Cloud requests go through
//  `MacOpenAIAPIClient`; on-device ones run `OnDeviceAnalysisEngine`, which is
//  shared with iOS (image mode on macOS 27+, OCR text mode on macOS 26).
//

import Foundation
import AppKit

enum MacScreenshotAnalysisService {

    /// Errors are `OpenAIError` (cloud) or `OnDeviceAnalysisError` (on-device).
    static func analyze(
        _ image: NSImage,
        engine: AnalysisEngine,
        customCategories: [CategoryPromptInfo],
        allowNewCategory: Bool,
        screenshotId: UUID?
    ) async throws -> [DraftItem] {
        switch engine {
        case .cloud:
            return try await MacOpenAIAPIClient.shared.analyzeScreenshot(
                image,
                customCategories: customCategories,
                allowNewCategory: allowNewCategory,
                screenshotId: screenshotId
            )
        case .onDevice:
            return try await analyzeOnDevice(
                image,
                customCategories: customCategories,
                allowNewCategory: allowNewCategory,
                screenshotId: screenshotId
            )
        }
    }

    private static func analyzeOnDevice(
        _ image: NSImage,
        customCategories: [CategoryPromptInfo],
        allowNewCategory: Bool,
        screenshotId: UUID?
    ) async throws -> [DraftItem] {
        // Same downscale as the cloud path — plenty for OCR and the model.
        guard let cgImage = image.resized(toMaxDimension: 1024).analysisCGImage else {
            throw OnDeviceAnalysisError.invalidImage
        }
        let hints = customCategories.map {
            AnalysisCategoryHint(key: $0.key, name: $0.name, hint: $0.hint)
        }
        let rawItems = try await OnDeviceAnalysisEngine.shared.analyze(
            cgImage: cgImage,
            orientation: .up,
            customCategories: hints,
            allowNewCategory: allowNewCategory
        )
        return rawItems.compactMap { dict -> DraftItem? in
            guard
                let category = dict["category"], !category.isEmpty,
                let title = dict["title"],
                !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return nil }
            return DraftItem(
                categoryKey: category,
                title: title,
                subtitle: dict["subtitle"] ?? "",
                link: dict["link"] ?? "",
                extra1: dict["extra1"] ?? "",
                extra2: dict["extra2"] ?? "",
                notes: dict["notes"] ?? "",
                suggestedCategoryName: dict["suggestedCategoryName"] ?? "",
                sourceScreenshotId: screenshotId
            )
        }
    }
}
