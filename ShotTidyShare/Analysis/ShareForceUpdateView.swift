//
//  ShareForceUpdateView.swift
//  ShotTidyShare
//
//  Blocking overlay for the Share Extension shown when a mandatory update is detected.
//  The user can open the App Store to update or close the extension.
//

import SwiftUI

struct ShareForceUpdateView: View {
    let storeURL: URL?
    let onCancel: () -> Void

    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: "arrow.down.app.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(.blue)
                }

                // Title
                Text("Update Required")
                    .font(.title2.weight(.bold))
                    .padding(.top, 24)

                // Body
                Text("A new version of ShotTidy is available.\nPlease update the app to continue using it.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 10)

                Spacer()

                VStack(spacing: 12) {
                    // Update button — opens App Store via SwiftUI environment (extension-safe)
                    Button {
                        if let url = storeURL {
                            openURL(url)
                        }
                    } label: {
                        Text("Update Now")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Close extension
                    Button("Close", action: onCancel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
    }
}
