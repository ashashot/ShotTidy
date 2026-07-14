//
//  ShareCatalogWriter.swift
//  ShotTidyShare
//
//  Writes confirmed draft items directly into the shared SwiftData store
//  (App Group container) so items appear in the catalog without opening the app.
//

import Foundation
import SwiftData
import UIKit

enum ShareCatalogWriter {

    /// Opens the shared SwiftData store and inserts one CatalogItem per draft,
    /// plus a Screenshot record linked to them (if a source image is provided).
    @MainActor
    static func save(_ items: [PendingDraftItem], sourceImage: UIImage? = nil) throws {
        let container = try makeContainer()
        let context = container.mainContext

        // Create a Screenshot record so the Screenshots tab shows the source image.
        let screenshotId: UUID?
        if let image = sourceImage, !items.isEmpty {
            let screenshot = Screenshot()
            screenshot.originalFileName = "share_screenshot.jpg"
            screenshot.createdAt = Date()
            screenshot.analyzedAt = Date()
            screenshot.analysisStatus = .done
            screenshot.extractedItemsCount = items.count

            screenshot.thumbnailData = image.resized(toMaxDimension: 800).jpegData(compressionQuality: 0.85)

            context.insert(screenshot)
            screenshotId = screenshot.id
        } else {
            screenshotId = nil
        }

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
            if let sid = screenshotId {
                item.sourceScreenshotId = sid
            }
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
        String(localized: "The App Group container is unavailable.", bundle: AppLocale.bundle)
    }
}
