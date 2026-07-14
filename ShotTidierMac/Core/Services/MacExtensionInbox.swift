//
//  MacExtensionInbox.swift
//  ShotTidierMac
//
//  Imports catalog items saved by the Safari extension. The extension writes
//  PendingDraftItems into the App Group container (same mechanism the iOS
//  Share Extension uses) and posts a distributed notification; this inbox
//  imports them into SwiftData on launch and whenever the notification fires,
//  which puts them on the normal CloudKit sync path.
//

import Foundation
import SwiftData

@Observable
@MainActor
final class MacExtensionInbox {

    /// Posted by SafariWebExtensionHandler after writing to the inbox.
    /// App-group-prefixed: sandboxed processes may only post distributed
    /// notifications named under an application group they belong to.
    static let notificationName = Notification.Name("group.com.mbx.ShotTidier.extensionInboxUpdated")

    /// Number of items brought in by the most recent import (for a UI banner).
    private(set) var lastImportCount = 0

    /// Increments on every successful import so the UI can react even when
    /// two consecutive imports bring the same item count.
    private(set) var importEvent = 0

    private var modelContext: ModelContext?
    // nonisolated(unsafe): only mutated on the main actor (start), read in deinit.
    nonisolated(unsafe) private var observer: NSObjectProtocol?

    deinit {
        if let observer {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }

    // MARK: - Lifecycle

    /// Call once when the main window appears. Imports anything already
    /// pending and subscribes to live updates from the extension.
    func start(context: ModelContext) {
        modelContext = context
        importPending()

        guard observer == nil else { return }
        observer = DistributedNotificationCenter.default().addObserver(
            forName: Self.notificationName,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.importPending()
            }
        }
    }

    // MARK: - Import

    func importPending() {
        guard let context = modelContext else { return }
        let pending = AppGroupManager.loadPendingDrafts()
        guard !pending.isEmpty else { return }

        var imported = 0
        for draft in pending {
            guard !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            // categoryKey init accepts built-in and custom keys alike.
            let item = CatalogItem(
                categoryKey: draft.categoryKey,
                title: draft.title,
                subtitle: draft.subtitle.isEmpty ? nil : draft.subtitle,
                link: draft.link.isEmpty ? nil : draft.link,
                extra1: draft.extra1.isEmpty ? nil : draft.extra1,
                extra2: draft.extra2.isEmpty ? nil : draft.extra2,
                notes: draft.notes.isEmpty ? nil : draft.notes
            )
            context.insert(item)
            imported += 1
        }

        do {
            try context.save()
        } catch {
            // Keep the inbox file so the import can be retried on the next
            // launch/notification instead of silently losing the items.
            context.rollback()
            return
        }
        AppGroupManager.clearPendingDrafts()
        guard imported > 0 else { return }
        lastImportCount = imported
        importEvent += 1
    }
}
