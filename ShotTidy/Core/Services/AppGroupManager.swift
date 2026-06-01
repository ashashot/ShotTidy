//
//  AppGroupManager.swift
//  ShotTidy
//
//  Shared container between the main app and the Share Extension.
//  Add this file to both targets: ShotTidy and ShotTidyShare.
//

import Foundation

// MARK: - CatalogIndexEntry

/// Lightweight snapshot of one CatalogItem, written by the main app into the App Group
/// so the Share Extension can check for duplicates without accessing SwiftData.
///
/// Only the fields used for matching are stored: title, subtitle, link, and category.
struct CatalogIndexEntry: Codable {
    let categoryKey: String
    let title: String
    let subtitle: String?
    let link: String?
}

// MARK: - PendingDraftItem

/// A confirmed draft item saved by the Share Extension, awaiting import into SwiftData.
/// Must stay Codable-compatible with ShareAppGroupManager.PendingDraftItem in the extension target.
struct PendingDraftItem: Codable, Identifiable {
    var id: UUID
    var categoryKey: String
    var title: String
    var subtitle: String
    var link: String
    var extra1: String
    var extra2: String
    var notes: String

    init(
        id: UUID = UUID(),
        categoryKey: String,
        title: String,
        subtitle: String = "",
        link: String = "",
        extra1: String = "",
        extra2: String = "",
        notes: String = ""
    ) {
        self.id = id
        self.categoryKey = categoryKey
        self.title = title
        self.subtitle = subtitle
        self.link = link
        self.extra1 = extra1
        self.extra2 = extra2
        self.notes = notes
    }
}

// MARK: - SharedCategory

/// Lightweight snapshot of a user-defined category, written by the main app into
/// the App Group so the Share Extension can match (and offer) custom categories.
struct SharedCategory: Codable {
    let key: String
    let name: String
    let icon: String
    let hint: String
}

// MARK: - AppGroupManager

enum AppGroupManager {
    static let groupID = "group.com.mbx.ShotTidier"

    /// URL of the shared App Group container
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
    }

    /// UserDefaults shared between the main app and the Share Extension.
    /// Falls back to .standard only if the App Group is misconfigured.
    /// Marked nonisolated so it can be used as a default parameter value
    /// in contexts that are not yet on the MainActor (e.g. init default args).
    nonisolated static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: groupID) ?? .standard
    }

    // MARK: - Subscription status bridge (main app → Share Extension)

    /// Written by the main app's SubscriptionManager when Pro status changes.
    /// Read by the Share Extension's ShareUsageManager to gate API calls.
    nonisolated static func saveIsProStatus(_ isPro: Bool) {
        sharedDefaults.set(isPro, forKey: "subscription.isPro")
    }

    nonisolated static func loadIsProStatus() -> Bool {
        sharedDefaults.bool(forKey: "subscription.isPro")
    }

    /// File URL for pending draft items JSON (new share extension flow)
    private static var pendingDraftsURL: URL? {
        containerURL?.appendingPathComponent("pending_drafts.json")
    }

    // MARK: - Pending Draft Items (new flow)

    /// Save items confirmed by the user in the Share Extension
    static func savePendingDrafts(_ items: [PendingDraftItem]) throws {
        guard let url = pendingDraftsURL else {
            throw AppGroupError.containerUnavailable
        }
        let data = try JSONEncoder().encode(items)
        try data.write(to: url, options: .atomic)
    }

    /// Load items saved by the Share Extension
    static func loadPendingDrafts() -> [PendingDraftItem] {
        guard
            let url = pendingDraftsURL,
            let data = try? Data(contentsOf: url),
            let items = try? JSONDecoder().decode([PendingDraftItem].self, from: data)
        else { return [] }
        return items
    }

    /// Remove the pending drafts file after successful import
    static func clearPendingDrafts() {
        guard let url = pendingDraftsURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - Catalog index (for Share Extension duplicate detection)

    private static var catalogIndexURL: URL? {
        containerURL?.appendingPathComponent("catalog_index.json")
    }

    /// Write the current catalog as a lightweight index to the App Group.
    /// Called by the main app so the Share Extension can check for duplicates.
    static func saveCatalogIndex(_ entries: [CatalogIndexEntry]) {
        guard let url = catalogIndexURL else { return }
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }

    /// Load the catalog index written by the main app.
    /// Used by the Share Extension for duplicate detection.
    static func loadCatalogIndex() -> [CatalogIndexEntry] {
        guard
            let url = catalogIndexURL,
            let data = try? Data(contentsOf: url),
            let entries = try? JSONDecoder().decode([CatalogIndexEntry].self, from: data)
        else { return [] }
        return entries
    }

    // MARK: - Custom categories (main app → Share Extension)

    private static let customCategoriesKey = "shared.customCategories"

    /// Mirror the user's custom categories so the Share Extension can use them.
    nonisolated static func saveCustomCategories(_ categories: [SharedCategory]) {
        if let data = try? JSONEncoder().encode(categories) {
            sharedDefaults.set(data, forKey: customCategoriesKey)
        }
    }

    nonisolated static func loadCustomCategories() -> [SharedCategory] {
        guard let data = sharedDefaults.data(forKey: customCategoriesKey),
              let entries = try? JSONDecoder().decode([SharedCategory].self, from: data) else {
            return []
        }
        return entries
    }

    // MARK: - Startup cleanup

    /// Remove the legacy PendingImages directory left over from an older flow.
    /// Call once at app launch; safe to call repeatedly (no-op if the directory is absent).
    static func purgeLegacyPendingImages() {
        guard let base = containerURL else { return }
        let legacyDir = base.appendingPathComponent("PendingImages", isDirectory: true)
        guard FileManager.default.fileExists(atPath: legacyDir.path) else { return }
        do {
            try FileManager.default.removeItem(at: legacyDir)
            print("[ShotTidy] Removed legacy PendingImages directory.")
        } catch {
            print("[ShotTidy] Could not remove legacy PendingImages directory: \(error)")
        }
    }
}

// MARK: - Errors

enum AppGroupError: LocalizedError {
    case containerUnavailable

    var errorDescription: String? {
        "The App Group shared container is unavailable. Check the group.com.mbx.ShotTidier configuration."
    }
}
