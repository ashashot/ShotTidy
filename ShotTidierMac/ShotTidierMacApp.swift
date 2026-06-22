//
//  ShotTidierMacApp.swift
//  ShotTidierMac
//
//  Entry point for the macOS version of ShotTidier.
//  NavigationSplitView (sidebar + content + detail) replaces the iOS TabView.
//

import SwiftUI
import SwiftData

@main
struct ShotTidierMacApp: App {

    @State private var categoryStore = CategoryStore()
    @State private var subscriptionManager = MacSubscriptionManager()
    @State private var syncMonitor = MacCloudSyncMonitor()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Screenshot.self,
            CatalogItem.self,
            UserCategory.self,
        ])
        let storeURL = URL.applicationSupportDirectory
            .appending(path: "ShotTidierMac", directoryHint: .isDirectory)
            .appending(path: "ShotTidy.sqlite")

        let isPro = MacSubscriptionManager.loadIsProStatus()

        if isPro {
            // Pro tier: CloudKit sync enabled — same container as iOS.
            let cloudConfig = ModelConfiguration(
                "ShotTidierMac",
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .private("iCloud.com.mbx.ShotTidier")
            )
            do {
                return try ModelContainer(for: schema, configurations: [cloudConfig])
            } catch {
                // Falling back to local-only storage. Log the reason so CloudKit
                // sync misconfiguration (entitlements, container schema) is visible.
                print("⚠️ CloudKit ModelContainer creation failed, falling back to local store: \(error)")
            }
        }

        // Free tier (or CloudKit fallback): local storage only.
        let localConfig = ModelConfiguration(
            "ShotTidierMac",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        guard let container = try? ModelContainer(for: schema, configurations: [localConfig]) else {
            fatalError("Failed to create ModelContainer")
        }
        return container
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(categoryStore)
                .environment(subscriptionManager)
                .environment(syncMonitor)
                .task {
                    await subscriptionManager.onLaunch()
                }
                .alert(
                    "Restart Required",
                    isPresented: .init(
                        get: { subscriptionManager.needsRestartForSyncChange },
                        set: { _ in subscriptionManager.acknowledgeRestartPrompt() }
                    )
                ) {
                    Button("OK") {
                        subscriptionManager.acknowledgeRestartPrompt()
                    }
                } message: {
                    if subscriptionManager.isProActive {
                        Text("iCloud sync has been enabled. Please restart the app to start syncing your catalog across devices.")
                    } else {
                        Text("iCloud sync has been disabled. Please restart the app to apply changes.")
                    }
                }
        }
        .modelContainer(sharedModelContainer)
        .commands {
            CommandGroup(after: .newItem) {
                EmptyView()
            }
        }

        Settings {
            MacSettingsView()
                .modelContainer(sharedModelContainer)
                .environment(subscriptionManager)
                .environment(syncMonitor)
        }
    }
}
