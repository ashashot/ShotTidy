//
//  ScreenshotAnalysisService.swift
//  ShotTidy
//
//  Single entry point for screenshot analysis in the main app. Resolves which
//  engine actually runs (the user's choice, or the cloud when the on-device
//  model is unavailable), dispatches to it, normalizes results into
//  `DraftItem`s, and classifies failures so the import flow treats cloud and
//  on-device errors the same way.
//

import Foundation
import UIKit

// MARK: - Failure classification

/// How the import flow should react to a per-screenshot failure.
enum AnalysisFailureKind {
    /// Server quota / rate limit — route the user to the paywall.
    case quotaExceeded
    /// This screenshot could not be analyzed; skip it with a warning and continue.
    case skippable
    /// Infrastructure problem (network, auth, model missing) — shown only when
    /// nothing at all was extracted.
    case hard
}

protocol AnalysisFailureClassifiable {
    var failureKind: AnalysisFailureKind { get }
}

extension OpenAIError: AnalysisFailureClassifiable {
    var failureKind: AnalysisFailureKind {
        switch self {
        case .quotaExceeded:              return .quotaExceeded
        case .refused, .emptyResponse:    return .skippable
        case .invalidImage, .httpError, .decodingFailed, .networkError:
            return .hard
        }
    }
}

extension OnDeviceAnalysisError: AnalysisFailureClassifiable {
    var failureKind: AnalysisFailureKind {
        switch self {
        case .unavailable, .underlying:
            return .hard
        case .invalidImage, .refused, .contextSizeExceeded, .rateLimited,
             .timeout, .unsupportedLanguage, .decodingFailed:
            // The user explicitly chose on-device for privacy — never fall
            // back to the cloud silently; skip the screenshot instead.
            return .skippable
        }
    }
}

extension Error {
    /// Defaults to `.hard` for errors the analysis layer does not know about.
    var analysisFailureKind: AnalysisFailureKind {
        (self as? AnalysisFailureClassifiable)?.failureKind ?? .hard
    }
}

// MARK: - Service

enum ScreenshotAnalysisService {

    /// Outcome of picking an engine for a run.
    struct Resolution: Equatable {
        /// Engine that will actually process the screenshots.
        let engine: AnalysisEngine
        /// Non-nil when the user asked for on-device analysis but it is not
        /// usable right now, so the cloud engine is used instead.
        let fallbackReason: OnDeviceAnalysisAvailability?
    }

    /// Honors the preferred engine when it can run; otherwise falls back to the
    /// cloud and reports why, so the UI can tell the user.
    static func resolve(preferred: AnalysisEngine) -> Resolution {
        switch preferred {
        case .cloud:
            return Resolution(engine: .cloud, fallbackReason: nil)
        case .onDevice:
            let availability = OnDeviceAnalysisEngine.availability
            if availability.isAvailable {
                return Resolution(engine: .onDevice, fallbackReason: nil)
            }
            return Resolution(engine: .cloud, fallbackReason: availability)
        }
    }

    /// Analyzes one screenshot with the given engine. Errors are
    /// `OpenAIError` (cloud) or `OnDeviceAnalysisError` (on-device) — both
    /// conform to `AnalysisFailureClassifiable`.
    static func analyze(
        _ image: UIImage,
        engine: AnalysisEngine,
        customCategories: [CategoryPromptInfo],
        allowNewCategory: Bool,
        screenshotId: UUID?,
        imageLabel: String
    ) async throws -> [DraftItem] {
        switch engine {
        case .cloud:
            return try await OpenAIAPIClient.shared.analyzeScreenshot(
                image,
                customCategories: customCategories,
                allowNewCategory: allowNewCategory,
                screenshotId: screenshotId,
                imageLabel: imageLabel
            )
        case .onDevice:
            return try await analyzeOnDevice(
                image,
                customCategories: customCategories,
                allowNewCategory: allowNewCategory,
                screenshotId: screenshotId,
                imageLabel: imageLabel
            )
        }
    }

    // MARK: - On-device path

    private static func analyzeOnDevice(
        _ image: UIImage,
        customCategories: [CategoryPromptInfo],
        allowNewCategory: Bool,
        screenshotId: UUID?,
        imageLabel: String
    ) async throws -> [DraftItem] {
        let engineName = AnalysisEngine.onDevice.rawValue

        guard let cgImage = image.cgImage else {
            await AnalysisLogger.shared.log(AnalysisLogEntry(
                imageLabel: imageLabel,
                outcome: .invalidImage,
                message: "Image has no bitmap data",
                engine: engineName
            ))
            throw OnDeviceAnalysisError.invalidImage
        }

        let hints = customCategories.map {
            AnalysisCategoryHint(key: $0.key, name: $0.name, hint: $0.hint)
        }

        let rawItems: [[String: String]]
        do {
            rawItems = try await OnDeviceAnalysisEngine.shared.analyze(
                cgImage: cgImage,
                orientation: image.cgImagePropertyOrientation,
                customCategories: hints,
                allowNewCategory: allowNewCategory
            )
        } catch {
            let mapped = (error as? OnDeviceAnalysisError) ?? .underlying(error)
            await AnalysisLogger.shared.log(AnalysisLogEntry(
                imageLabel: imageLabel,
                outcome: logOutcome(for: mapped),
                message: mapped.localizedDescription,
                engine: engineName
            ))
            throw mapped
        }

        let drafts = rawItems.compactMap { dict -> DraftItem? in
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

        await AnalysisLogger.shared.log(AnalysisLogEntry(
            imageLabel: imageLabel,
            outcome: drafts.isEmpty ? .emptyItems : .success,
            itemCount: drafts.count,
            message: drafts.isEmpty
                ? "On-device model returned no items"
                : "Extracted \(drafts.count) item(s) on device",
            engine: engineName
        ))

        return drafts
    }

    private static func logOutcome(for error: OnDeviceAnalysisError) -> AnalysisLogOutcome {
        switch error {
        case .unavailable:          return .engineUnavailable
        case .invalidImage:         return .invalidImage
        case .refused:              return .refused
        case .decodingFailed:       return .decodingFailed
        case .rateLimited:          return .quotaExceeded
        case .contextSizeExceeded, .timeout, .unsupportedLanguage, .underlying:
            return .engineError
        }
    }
}
