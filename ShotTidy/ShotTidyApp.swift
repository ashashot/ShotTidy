//
//  ShotTidyApp.swift
//  ShotTidy
//

import SwiftUI
import SwiftData

@main
struct ShotTidyApp: App {

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

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
