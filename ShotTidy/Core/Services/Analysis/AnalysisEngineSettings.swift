//
//  AnalysisEngineSettings.swift
//  ShotTidy
//
//  Observable snapshot of the engine this device uses. There is no user choice:
//  `AnalysisEngineResolver` decides from the device's Apple Intelligence state,
//  and this object exposes the result to Settings and Import so they can show
//  which engine runs and why.
//
//  Shared by the iOS and macOS apps — Foundation only.
//

import Foundation
import Observation

@Observable
@MainActor
final class AnalysisEngineSettings {

    /// Current decision; call `refreshAvailability()` when a screen that
    /// depends on it appears.
    private(set) var resolution: AnalysisEngineResolver.Resolution

    init() {
        resolution = Self.currentResolution()
    }

    /// Engine that will run, or `nil` on an unsupported device (Mac without
    /// Apple Intelligence).
    var engine: AnalysisEngine? { resolution.engine }

    var onDeviceAvailability: OnDeviceAnalysisAvailability { resolution.availability }

    var isOnDeviceAvailable: Bool { onDeviceAvailability.isAvailable }

    var isUnsupported: Bool { resolution.isUnsupported }

    /// Re-reads the system model state (Apple Intelligence can be toggled or
    /// finish downloading while the app is running).
    func refreshAvailability() {
        resolution = Self.currentResolution()
    }

    private static func currentResolution() -> AnalysisEngineResolver.Resolution {
        #if DEBUG && os(iOS)
        // App Store screenshot scenes show the on-device engine regardless of the simulator's model state.
        if DemoMode.isActive { return .onDevice(.available) }
        #endif
        return AnalysisEngineResolver.resolve()
    }

    /// Whether the plan allows this engine — delegates to the tiering hook.
    func isAllowed(_ engine: AnalysisEngine, isPro: Bool) -> Bool {
        AnalysisEnginePolicy.isAllowed(engine, isPro: isPro)
    }
}
