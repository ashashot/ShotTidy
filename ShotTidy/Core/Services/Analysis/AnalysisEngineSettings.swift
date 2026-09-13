//
//  AnalysisEngineSettings.swift
//  ShotTidy
//
//  Observable wrapper around the user's analysis-engine choice. Persists an
//  explicit selection to the App Group (so the Share Extension follows it) and
//  exposes the live availability of the on-device model for Settings and Import.
//
//  Until the user picks something, `selectedEngine` tracks the implicit
//  default: on-device when this device can run it, otherwise cloud — with no
//  fallback notice, because nothing the user asked for is being overridden.
//
//  Shared by the iOS and macOS apps — Foundation only.
//

import Foundation
import Observation

@Observable
@MainActor
final class AnalysisEngineSettings {

    /// Engine to run with. Setting it records an explicit user choice.
    var selectedEngine: AnalysisEngine {
        didSet {
            guard !isApplyingImplicitDefault else { return }
            hasExplicitChoice = true
            AppGroupManager.saveAnalysisEngine(selectedEngine)
        }
    }

    /// True once the user picked an engine in Settings (persisted).
    private(set) var hasExplicitChoice: Bool

    /// Snapshot of on-device availability; call `refreshAvailability()` when a
    /// screen that depends on it appears.
    private(set) var onDeviceAvailability: OnDeviceAnalysisAvailability

    private var isApplyingImplicitDefault = false

    init() {
        onDeviceAvailability = OnDeviceAnalysisEngine.availability
        if let stored = AppGroupManager.loadStoredAnalysisEngine() {
            selectedEngine = stored
            hasExplicitChoice = true
        } else {
            selectedEngine = AnalysisEngineResolver.implicitEngine()
            hasExplicitChoice = false
        }
    }

    var isOnDeviceAvailable: Bool { onDeviceAvailability.isAvailable }

    /// Engine that will actually run: the selection when usable, else the cloud.
    var effectiveEngine: AnalysisEngine {
        AnalysisEngineResolver.resolve(preferred: selectedEngine).engine
    }

    /// Re-reads the system model state (Apple Intelligence can be toggled or
    /// finish downloading while the app is running). Without an explicit
    /// choice the implicit default follows the new availability.
    func refreshAvailability() {
        onDeviceAvailability = OnDeviceAnalysisEngine.availability
        guard !hasExplicitChoice else { return }
        let implicit = AnalysisEngineResolver.implicitEngine()
        if implicit != selectedEngine {
            isApplyingImplicitDefault = true
            selectedEngine = implicit
            isApplyingImplicitDefault = false
        }
    }

    /// Whether the plan allows this engine — delegates to the tiering hook.
    func isAllowed(_ engine: AnalysisEngine, isPro: Bool) -> Bool {
        AnalysisEnginePolicy.isAllowed(engine, isPro: isPro)
    }
}
