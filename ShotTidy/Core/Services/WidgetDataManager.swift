//
//  WidgetDataManager.swift
//  ShotTidy
//
//  Writes a lightweight catalog snapshot to the App Group container so the
//  Widget Extension can read items without SwiftData access.
//  Also manages the pending-toggle queue produced by interactive checklist buttons.
//

import Foundation
import SwiftData
import WidgetKit

enum WidgetDataManager {

    // MARK: - Snapshot types
    // Field names must stay in sync with WidgetModels.swift in the widget target.

    struct WidgetCatalogItem: Codable {
        let id: UUID
        let categoryKey: String
        let title: String
        let subtitle: String?
        let isCompleted: Bool
        let createdAt: Date
    }

    struct WidgetSnapshot: Codable {
        var items: [WidgetCatalogItem]
        let updatedAt: Date
        let isPro: Bool
        let enrichmentBalance: Int
        let screenshotsThisPeriod: Int
    }

    // MARK: - Write snapshot

    @MainActor
    static func writeSnapshot(context: ModelContext) {
        guard let url = snapshotURL else { return }

        let descriptor = FetchDescriptor<CatalogItem>(
            sortBy: [SortDescriptor(\CatalogItem.createdAt, order: .reverse)]
        )
        guard let items = try? context.fetch(descriptor) else { return }

        let snapshot = WidgetSnapshot(
            items: items.map {
                WidgetCatalogItem(
                    id: $0.id,
                    categoryKey: $0.categoryRaw,
                    title: $0.title,
                    subtitle: $0.subtitle,
                    isCompleted: $0.isCompleted,
                    createdAt: $0.createdAt
                )
            },
            updatedAt: Date(),
            isPro: AppGroupManager.loadIsProStatus(),
            enrichmentBalance: UsageStore.shared.integer(forKey: "usage.purchasedCredits")
                             + UsageStore.shared.integer(forKey: "usage.proCredits"),
            screenshotsThisPeriod: UsageStore.shared.integer(forKey: "usage.screenshotsThisPeriod")
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Apply pending toggles (widget → SwiftData)

    /// Reads completion-toggle requests queued by interactive widget buttons,
    /// applies them to SwiftData, and clears the queue.
    /// Returns `true` when at least one item was changed.
    @discardableResult
    @MainActor
    static func applyPendingToggles(context: ModelContext) -> Bool {
        guard
            let data = AppGroupManager.sharedDefaults.data(forKey: pendingTogglesKey),
            let pendingIDs = try? JSONDecoder().decode([UUID].self, from: data),
            !pendingIDs.isEmpty
        else { return false }

        var changed = false
        for itemID in pendingIDs {
            let id = itemID
            let fetch = FetchDescriptor<CatalogItem>(predicate: #Predicate { $0.id == id })
            if let item = try? context.fetch(fetch).first {
                item.isCompleted.toggle()
                changed = true
            }
        }

        AppGroupManager.sharedDefaults.removeObject(forKey: pendingTogglesKey)
        if changed { try? context.save() }
        return changed
    }

    // MARK: - Widget reload

    static func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Private

    private static let snapshotFileName  = "widget_snapshot.json"
    private static let pendingTogglesKey = "widget.pendingToggles"

    private static var snapshotURL: URL? {
        AppGroupManager.containerURL?.appendingPathComponent(snapshotFileName)
    }
}
