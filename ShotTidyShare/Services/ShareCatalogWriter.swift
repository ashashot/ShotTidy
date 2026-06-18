//
//  ShareCatalogWriter.swift
//  ShotTidyShare
//
//  Writes confirmed draft items directly into the shared SwiftData store
//  (App Group container) so items appear in the catalog without opening the app.
//

import Foundation
import SwiftData

enum ShareCatalogWriter {

    /// Opens the shared SwiftData store and inserts one CatalogItem per draft.
    /// The store lives in the App Group container, accessible by both targets.
    @MainActor
    static func save(_ items: [PendingDraftItem]) throws {
        let container = try makeContainer()
        let context = container.mainContext

        for draft in items {
            let item = CatalogItem(
                categoryKey: draft.categoryKey,
                title:       draft.title,
                subtitle:    draft.subtitle.isEmpty ? nil : draft.subtitle,
                link:        draft.link.isEmpty     ? nil : draft.link,
                extra1:      draft.extra1.isEmpty   ? nil : draft.extra1,
                extra2:      draft.extra2.isEmpty   ? nil : draft.extra2,
                notes:       draft.notes.isEmpty    ? nil : draft.notes
            )
            context.insert(item)
        }

        try context.save()
    }

    // MARK: - Private

    private static func makeContainer() throws -> ModelContainer {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppGroupManager.groupID
        ) else {
            throw ShareCatalogError.containerUnavailable
        }
        let storeURL = groupURL.appending(path: "ShotTidy.sqlite")
        let schema = Schema([CatalogItem.self, Screenshot.self, UserCategory.self])
        // Extensions never sync CloudKit — the main app handles that on next launch.
        let config = ModelConfiguration(
            "ShotTidy",
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}

enum ShareCatalogError: LocalizedError {
    case containerUnavailable

    var errorDescription: String? {
        "The App Group container is unavailable."
    }
}
