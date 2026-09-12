//
//  AnalysisEngineSettings.swift
//  ShotTidy
//
//  Observable wrapper around the user's analysis-engine choice. Persists the
//  selection to the App Group (so the Share Extension follows it) and exposes
//  the live availability of the on-device model for Settings and Import.
//

import Foundation
import Observation

@Observable
@MainActor
final class AnalysisEngineSettings {

    /// Engine the user picked in Settings. Persisted across launches.
    var selectedEngine: AnalysisEngine {
        didSet { AppGroupManager.saveAnalysisEngine(selectedEngine) }
    }

    /// Snapshot of on-device availability; call `refreshAvailability()` when a
    /// screen that depends on it appears.
    private(set) var onDeviceAvailability: OnDeviceAnalysisAvailability

    init() {
        selectedEngine = AppGroupManager.loadAnalysisEngine()
        onDeviceAvailability = OnDeviceAnalysisEngine.availability
    }

    var isOnDeviceAvailable: Bool { onDeviceAvailability.isAvailable }

    /// Engine that will actually run: the selection when usable, else the cloud.
    var effectiveEngine: AnalysisEngine {
        ScreenshotAnalysisService.resolve(preferred: selectedEngine).engine
    }

    /// Re-reads the system model state (Apple Intelligence can be toggled or
    /// finish downloading while the app is running).
    func refreshAvailability() {
        onDeviceAvailability = OnDeviceAnalysisEngine.availability
    }

    /// Whether the plan allows this engine — delegates to the tiering hook.
    func isAllowed(_ engine: AnalysisEngine, isPro: Bool) -> Bool {
        AnalysisEnginePolicy.isAllowed(engine, isPro: isPro)
    }
}
