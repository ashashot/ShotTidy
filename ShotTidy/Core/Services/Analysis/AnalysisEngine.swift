//
//  AnalysisEngine.swift
//  ShotTidy
//
//  Which backend extracts catalog items from a screenshot.
//
//  The engine is decided by the device, not by the user:
//
//  • iPhone / iPad that can run Apple Intelligence → on-device model.
//  • iPhone / iPad that cannot → cloud (OpenAI via the Edge Function).
//  • Mac → on-device only; a Mac that cannot run the model is unsupported and
//    the app refuses to work there (see `MacUnsupportedDeviceView`).
//
//  Plans are unaffected: both engines are allowed on every plan and both count
//  toward the same screenshot quota. `AnalysisEnginePolicy` stays the single
//  place to change that later.
//
//  Foundation-only and cross-compiled into the Share Extension, the Safari
//  extension and the macOS app so every process reaches the same decision.
//

import Foundation

// MARK: - AnalysisEngine

enum AnalysisEngine: String, CaseIterable, Identifiable, Codable, Sendable {
    /// OpenAI via the Supabase Edge Function.
    case cloud
    /// Apple Intelligence on-device model via Foundation Models
    /// (image mode on iOS/macOS 27+, OCR text mode on iOS/macOS 26).
    case onDevice

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .cloud:    return String(localized: "Cloud", bundle: AppLocale.bundle)
        case .onDevice: return String(localized: "On-Device (Apple Intelligence)", bundle: AppLocale.bundle)
        }
    }

    /// One-line explanation shown under the engine in Settings.
    var localizedSummary: String {
        switch self {
        case .cloud:
            return String(localized: "Screenshots are uploaded and analyzed in the cloud.", bundle: AppLocale.bundle)
        case .onDevice:
            return String(localized: "Private and works offline. Screenshots never leave your device.", bundle: AppLocale.bundle)
        }
    }

    var iconName: String {
        switch self {
        case .cloud:    return "cloud.fill"
        case .onDevice: return "apple.intelligence"
        }
    }

    /// Whether analyses through this engine count toward the free screenshot
    /// quota. Kept in one place so a future tier can waive local analyses
    /// without touching the import flow.
    var countsTowardScreenshotQuota: Bool { true }
}

// MARK: - Plan / platform policy

enum AnalysisEnginePolicy {
    /// Engine every device is expected to use when it can run it.
    static let defaultEngine: AnalysisEngine = .onDevice

    /// Whether a device that cannot run the on-device model may analyze in the
    /// cloud instead. iPhone/iPad: yes. Mac: no — the Mac app requires Apple
    /// Intelligence and is unsupported without it.
    static var allowsCloudFallback: Bool {
        #if os(macOS)
        return false
        #else
        return true
        #endif
    }

    /// Whether the plan allows this engine. Always true today; a future
    /// "on-device only" tier would return false for `.cloud` on that plan.
    static func isAllowed(_ engine: AnalysisEngine, isPro: Bool) -> Bool {
        true
    }
}

// MARK: - Resolution (which engine actually runs)

enum AnalysisEngineResolver {

    /// What this device does with a screenshot. Carries the on-device
    /// availability so the UI can explain the outcome.
    enum Resolution: Equatable, Sendable {
        /// The on-device model runs (image or OCR text mode).
        case onDevice(OnDeviceAnalysisAvailability)
        /// The device cannot run the on-device model; the cloud does the work.
        case cloud(OnDeviceAnalysisAvailability)
        /// The device cannot run the on-device model and the platform has no
        /// cloud fallback (Mac) — analysis is impossible here.
        case unsupported(OnDeviceAnalysisAvailability)

        /// Engine to run, or `nil` when the device is unsupported.
        var engine: AnalysisEngine? {
            switch self {
            case .onDevice:    return .onDevice
            case .cloud:       return .cloud
            case .unsupported: return nil
            }
        }

        var availability: OnDeviceAnalysisAvailability {
            switch self {
            case .onDevice(let a), .cloud(let a), .unsupported(let a): return a
            }
        }

        var isUnsupported: Bool {
            if case .unsupported = self { return true }
            return false
        }
    }

    /// Decides the engine from the current state of the system model. Cheap;
    /// re-check before every run because Apple Intelligence can be toggled or
    /// finish downloading while the app is open.
    static func resolve() -> Resolution {
        let availability = OnDeviceAnalysisEngine.availability
        if availability.isAvailable {
            return .onDevice(availability)
        }
        return AnalysisEnginePolicy.allowsCloudFallback
            ? .cloud(availability)
            : .unsupported(availability)
    }
}

// MARK: - Category hint passed to any engine

/// Minimal description of a user-defined category for prompt building.
/// Mirrors `CategoryPromptInfo` (main app) and `SharedCategory` (App Group)
/// without depending on either, so the on-device engine compiles everywhere.
struct AnalysisCategoryHint: Sendable, Equatable {
    let key: String
    let name: String
    let hint: String
}
