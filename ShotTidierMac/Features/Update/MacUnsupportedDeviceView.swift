//
//  MacUnsupportedDeviceView.swift
//  ShotTidierMac
//
//  Non-dismissable full-window overlay shown when this Mac cannot run the
//  on-device model. The Mac app analyzes screenshots only with Apple
//  Intelligence (no cloud fallback on macOS), so without it the app does not
//  work. Offers to open System Settings when the user can fix it themselves.
//

import SwiftUI
import AppKit

struct MacUnsupportedDeviceView: View {

    let availability: OnDeviceAnalysisAvailability
    let onCheckAgain: () -> Void

    /// Apple Intelligence is off or still downloading — the user can fix that.
    private var canBeFixedInSettings: Bool {
        switch availability {
        case .appleIntelligenceNotEnabled, .modelNotReady: return true
        default: return false
        }
    }

    private var title: String {
        canBeFixedInSettings ? "Apple Intelligence Required" : "This Mac Is Not Supported"
    }

    private var message: String {
        "ShotTidier for Mac analyzes screenshots only with Apple Intelligence on this Mac. "
            + availability.localizedDescription
    }

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 108, height: 108)
                    Image(systemName: canBeFixedInSettings ? "apple.intelligence" : "desktopcomputer.trianglebadge.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue)
                }

                Text(title)
                    .font(.title.weight(.bold))
                    .padding(.top, 28)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 12)

                Spacer()

                VStack(spacing: 10) {
                    if canBeFixedInSettings {
                        Button {
                            openAppleIntelligenceSettings()
                        } label: {
                            Text("Open System Settings")
                                .font(.headline)
                                .frame(maxWidth: 320)
                                .padding(.vertical, 14)
                                .background(Color.blue)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }

                    Button("Check Again") { onCheckAgain() }
                        .buttonStyle(.link)
                }
                .padding(.bottom, 48)
            }
        }
    }

    /// Opens the Apple Intelligence & Siri pane; falls back to System Settings itself.
    private func openAppleIntelligenceSettings() {
        let pane = URL(string: "x-apple.systempreferences:com.apple.Siri-Settings.extension")
        let app = URL(fileURLWithPath: "/System/Applications/System Settings.app")
        if let pane, NSWorkspace.shared.open(pane) { return }
        NSWorkspace.shared.open(app)
    }
}
