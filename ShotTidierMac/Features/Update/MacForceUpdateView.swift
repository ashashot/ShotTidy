//
//  MacForceUpdateView.swift
//  ShotTidierMac
//
//  Non-dismissable full-window overlay shown when AppUpdateService.state == .required.
//  Covers the entire UI; the only available action is opening the App Store.
//

import SwiftUI
import AppKit

struct MacForceUpdateView: View {

    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 108, height: 108)
                    Image(systemName: "arrow.down.app.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.blue)
                }

                // Title
                Text("Update Required")
                    .font(.title.weight(.bold))
                    .padding(.top, 28)

                // Body
                Text("A new version of ShotTidier is available.\nPlease update the app to continue using it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 12)

                Spacer()

                // Update button
                Button {
                    if let url = Config.appStoreURL {
                        NSWorkspace.shared.open(url)
                    }
                } label: {
                    Text("Update Now")
                        .font(.headline)
                        .frame(maxWidth: 320)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 48)
            }
        }
    }
}
