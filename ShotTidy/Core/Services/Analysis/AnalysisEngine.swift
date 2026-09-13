//
//  AnalysisEngine.swift
//  ShotTidy
//
//  Which backend extracts catalog items from a screenshot.
//
//  Foundation-only and cross-compiled into the Share Extension so both
//  processes honor the same user choice (persisted in the App Group defaults).
//
//  Tiering hook: `AnalysisEnginePolicy` is the single place to gate engines by
//  plan later (e.g. an "on-device only" tier vs. "on-device + cloud"). Today
//  every engine is allowed on every plan and both count toward the same
//  screenshot quota, so the business rules are unchanged.
//
//  Also compiled into the macOS app — Foundation only, no UIKit/AppKit.
//

import Foundation

// MARK: - AnalysisEngine

enum AnalysisEngine: String, CaseIterable, Identifiable, Codable, Sendable {
    /// GPT-4o via the Supabase Edge Function (the original implementation).
    case cloud
    /// Apple Intelligence on-device model via Foundation Models
    /// (image mode on iOS/macOS 27+, OCR text mode on iOS/macOS 26).
    case onDevice

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .cloud:    return String(localized: "Cloud (GPT-4o)", bundle: AppLocale.bundle)
        case .onDevice: return String(localized: "On-Device (Apple Intelligence)", bundle: AppLocale.bundle)
        }
    }

    /// One-line explanation shown under the option in Settings.
    var localizedSummary: String {
        switch self {
        case .cloud:
            return String(localized: "Best accuracy. Screenshots are uploaded for analysis.", bundle: AppLocale.bundle)
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

// MARK: - Plan policy (future tiers)

enum AnalysisEnginePolicy {
    /// Engine preferred when the user has never made a choice. On-device is
    /// the default; devices that cannot run it silently use the cloud (see
    /// `AnalysisEngineResolver`) — no warning is shown for an implicit default.
    static let defaultEngine: AnalysisEngine = .onDevice

    /// Whether the plan allows this engine. Always true today; a future
    /// "on-device only" tier would return false for `.cloud` on that plan.
    static func isAllowed(_ engine: AnalysisEngine, isPro: Bool) -> Bool {
        true
    }
}

// MARK: - Resolution (which engine actually runs)

enum AnalysisEngineResolver {

    /// Outcome of picking an engine for a run.
    struct Resolution: Equatable {
        /// Engine that will actually process the screenshots.
        let engine: AnalysisEngine
        /// Non-nil when on-device was requested but is not usable right now,
        /// so the cloud engine is used instead.
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

    /// Engine to use when the user never chose one: the policy default if it
    /// can run here, otherwise the cloud — quietly, without a fallback notice.
    static func implicitEngine() -> AnalysisEngine {
        resolve(preferred: AnalysisEnginePolicy.defaultEngine).engine
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

// MARK: - Persistence (App Group)

extension AppGroupManager {
    private nonisolated static let analysisEngineKey = "settings.analysisEngine"

    /// Persists the engine chosen in Settings so the Share Extension uses it too.
    nonisolated static func saveAnalysisEngine(_ engine: AnalysisEngine) {
        sharedDefaults.set(engine.rawValue, forKey: analysisEngineKey)
    }

    /// Engine explicitly chosen in Settings, or `nil` when the user never chose.
    nonisolated static func loadStoredAnalysisEngine() -> AnalysisEngine? {
        guard
            let raw = sharedDefaults.string(forKey: analysisEngineKey),
            let engine = AnalysisEngine(rawValue: raw)
        else { return nil }
        return engine
    }

    /// Engine to run with: the stored choice, or the implicit default resolved
    /// for this device (on-device when it can run, else cloud).
    nonisolated static func loadAnalysisEngine() -> AnalysisEngine {
        loadStoredAnalysisEngine() ?? AnalysisEngineResolver.implicitEngine()
    }
}
