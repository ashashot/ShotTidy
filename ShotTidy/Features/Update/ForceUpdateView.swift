//
//  ForceUpdateView.swift
//  ShotTidy
//
//  Non-dismissable full-screen overlay shown when AppUpdateService.state == .required.
//  Covers the entire UI; the only available action is opening the App Store.
//

import SwiftUI

struct ForceUpdateView: View {

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
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text("Update Now")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
