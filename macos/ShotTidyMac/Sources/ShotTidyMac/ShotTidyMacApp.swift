//
//  ShotTidyMacApp.swift
//  ShotTidyMac
//
//  Entry point for the macOS version of ShotTidy.
//  NavigationSplitView (sidebar + content + detail) replaces the iOS TabView.
//

import SwiftUI
import SwiftData

@main
struct ShotTidyMacApp: App {

    @State private var categoryStore = CategoryStore()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Screenshot.self,
            CatalogItem.self,
            UserCategory.self,
        ])
        let storeURL = URL.applicationSupportDirectory
            .appending(path: "ShotTidyMac", directoryHint: .isDirectory)
            .appending(path: "ShotTidy.sqlite")

        let config = ModelConfiguration(
            "ShotTidyMac",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        guard let container = try? ModelContainer(for: schema, configurations: [config]) else {
            fatalError("Failed to create ModelContainer")
        }
        return container
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(categoryStore)
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
        }
    }
}
