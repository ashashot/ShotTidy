//
//  ShotTidyApp.swift
//  ShotTidy
//

import SwiftUI
import SwiftData

@main
struct ShotTidyApp: App {

    // MARK: - Managers (injected into the environment)

    @State private var subscriptionManager = SubscriptionManager()
    @State private var usageManager        = UsageManager()

    // MARK: - Init

    init() {
        // OpenAI key now lives in Supabase Secrets (server-side).
        // No local key to sync — AppGroupManager.apiKey is no longer used.

        // Remove the legacy PendingImages directory left over from v1 of the Share Extension flow.
        AppGroupManager.purgeLegacyPendingImages()
    }

    // MARK: - SwiftData container

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Screenshot.self,
            CatalogItem.self,
        ])

        // Both tiers use the same SQLite file so data is preserved across tier changes.
        // CloudKit sync is layered on top for Pro users — no migration needed.
        let storeURL = URL.applicationSupportDirectory
            .appending(path: "ShotTidy.sqlite")

        let isPro = AppGroupManager.loadIsProStatus()

        if isPro {
            // Pro tier: CloudKit sync enabled.
            // The container ID is kept as iCloud.mbx.ShotTidy (declared in entitlements)
            // so existing records sync correctly regardless of the app bundle ID.
            let cloudConfig = ModelConfiguration(
                "ShotTidy",
                schema: schema,
                url: storeURL,
                cloudKitDatabase: .private("iCloud.mbx.ShotTidy")
            )
            if let container = try? ModelContainer(for: schema, configurations: [cloudConfig]) {
                return container
            }
        }

        // Free tier (or CloudKit fallback): local storage only, no sync.
        let localConfig = ModelConfiguration(
            "ShotTidy",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        if let container = try? ModelContainer(for: schema, configurations: [localConfig]) {
            return container
        }

        fatalError("Failed to create ModelContainer")
    }()

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(subscriptionManager)
                .environment(usageManager)
                .task {
                    // Load StoreKit products and verify subscription status on launch.
                    await subscriptionManager.onLaunch()
                    // Check rolling 30-day reset now that we know the subscription state.
                    usageManager.performRollingReset(isPro: subscriptionManager.isProActive)
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
    }
}
