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

import Foundation

// MARK: - AnalysisEngine

enum AnalysisEngine: String, CaseIterable, Identifiable, Codable, Sendable {
    /// GPT-4o via the Supabase Edge Function (the original implementation).
    case cloud
    /// Apple Intelligence on-device model via Foundation Models (iOS 27+).
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
    /// Engine used when the user has never made a choice.
    static let defaultEngine: AnalysisEngine = .cloud

    /// Whether the plan allows this engine. Always true today; a future
    /// "on-device only" tier would return false for `.cloud` on that plan.
    static func isAllowed(_ engine: AnalysisEngine, isPro: Bool) -> Bool {
        true
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

    /// Engine chosen in Settings, or the policy default when never set.
    nonisolated static func loadAnalysisEngine() -> AnalysisEngine {
        guard
            let raw = sharedDefaults.string(forKey: analysisEngineKey),
            let engine = AnalysisEngine(rawValue: raw)
        else { return AnalysisEnginePolicy.defaultEngine }
        return engine
    }
}
