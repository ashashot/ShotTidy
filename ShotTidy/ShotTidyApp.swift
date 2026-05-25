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

        // Сначала пробуем CloudKit (метаданные CatalogItem синхронизируются)
        if let container = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)]
        ) { return container }

        // Fallback — только локальное хранилище
        if let container = try? ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)]
        ) { return container }

        fatalError("Не удалось создать ModelContainer")
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}
