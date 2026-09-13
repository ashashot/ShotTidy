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
        resolution = AnalysisEngineResolver.resolve()
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
        resolution = AnalysisEngineResolver.resolve()
    }

    /// Whether the plan allows this engine — delegates to the tiering hook.
    func isAllowed(_ engine: AnalysisEngine, isPro: Bool) -> Bool {
        AnalysisEnginePolicy.isAllowed(engine, isPro: isPro)
    }
}
