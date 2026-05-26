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

        // First try CloudKit (CatalogItem metadata is synced)
        if let container = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)]
        ) { return container }

        // Fallback — local storage only
        if let container = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
        ) { return container }

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
        }
        .modelContainer(sharedModelContainer)
    }
}
