//
//  WidgetDataReader.swift
//  ShotTidyWidget
//
//  Reads the catalog snapshot written by the main app and manages the
//  pending-toggle queue for interactive checklist buttons.
//

import Foundation
import WidgetKit

enum WidgetDataReader {

    private static let groupID           = "group.com.mbx.ShotTidier"
    private static let snapshotFileName  = "widget_snapshot.json"
    private static let pendingTogglesKey = "widget.pendingToggles"

    private static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
    }

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: groupID) ?? .standard
    }

    // MARK: - Snapshot

    static func readSnapshot() -> WidgetSnapshot {
        guard
            let url  = containerURL?.appendingPathComponent(snapshotFileName),
            let data = try? Data(contentsOf: url),
            let snap = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else { return .empty }
        return snap
    }

    // MARK: - Interactive toggle queue

    /// Queues a completion toggle for the given item, then optimistically flips
    /// its `isCompleted` in the on-disk snapshot so the widget reflects the change
    /// immediately — before the main app has a chance to apply it.
    static func queueToggle(itemID: UUID) {
        var pending = loadPendingToggles()
        if let idx = pending.firstIndex(of: itemID) {
            // Tapped twice: undo the first queued request.
            pending.remove(at: idx)
        } else {
            pending.append(itemID)
        }
        savePendingToggles(pending)
        optimisticallyToggle(itemID: itemID)
    }

    // MARK: - Private

    private static func optimisticallyToggle(itemID: UUID) {
        guard let url = containerURL?.appendingPathComponent(snapshotFileName) else { return }
        var snap = readSnapshot()
        snap.items = snap.items.map { item in
            guard item.id == itemID else { return item }
            return WidgetCatalogItem(
                id: item.id,
                categoryKey: item.categoryKey,
                title: item.title,
                subtitle: item.subtitle,
                isCompleted: !item.isCompleted,
                createdAt: item.createdAt
            )
        }
        if let data = try? JSONEncoder().encode(snap) {
            try? data.write(to: url, options: .atomic)
        }
    }

    private static func loadPendingToggles() -> [UUID] {
        guard
            let data = defaults.data(forKey: pendingTogglesKey),
            let ids  = try? JSONDecoder().decode([UUID].self, from: data)
        else { return [] }
        return ids
    }

    private static func savePendingToggles(_ ids: [UUID]) {
        guard let data = try? JSONEncoder().encode(ids) else { return }
        defaults.set(data, forKey: pendingTogglesKey)
    }
}
