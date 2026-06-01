//
//  AppGroupManager.swift
//  ShotTidy
//
//  Shared container between the main app and the Share Extension.
//  Add this file to both targets: ShotTidy and ShotTidyShare.
//

import Foundation
import Security

// MARK: - UsageStore (Keychain-backed, survives app reinstall)

/// Persistent storage for free-tier usage counters and credit balances.
///
/// Backed by the Keychain (shared access group) instead of UserDefaults, so the
/// values survive an app delete + reinstall on the same device — closing the
/// "delete to reset free limits" loophole. The App Group UserDefaults is kept as
/// a fast cache and as the migration source for users created before this change.
///
/// Exposes the same method names as `UserDefaults` (`integer`/`bool`/`object`/`set`)
/// so existing call sites change only their storage type, not their logic.
///
/// All values are stored as `Double` in a single JSON Keychain item:
///   Int  → Double      Bool → 0/1      Date → timeIntervalSince1970 (Double)
///
/// Note: app and Share Extension are separate processes. They very rarely write
/// concurrently (extension runs while sharing; app runs in foreground), so the
/// read-modify-write of the backing dictionary is acceptable without locking.
final class UsageStore {

    nonisolated(unsafe) static let shared = UsageStore()

    private let account = "usage.counters"
    private let service = "com.mbx.ShotTidy.usage"

    /// Fully-qualified shared keychain access group (`<TeamID>.com.mbx.ShotTidy.usage`),
    /// resolved at runtime so the Team ID is never hardcoded. `nil` means the
    /// access group could not be determined — we then fall back to the target's
    /// default keychain (still survives reinstall, but won't share across targets).
    private let accessGroup: String?

    private var cache: [String: Double]
    private let mirror: UserDefaults

    private init() {
        mirror = UserDefaults(suiteName: AppGroupManager.groupID) ?? .standard
        accessGroup = UsageStore.resolveAccessGroup(suffix: "com.mbx.ShotTidy.usage")
        cache = UsageStore.readKeychain(
            account: account, service: service, accessGroup: accessGroup
        ) ?? [:]

        // One-time migration: if the Keychain is empty but legacy UserDefaults
        // values exist, adopt them so current users keep their progress/credits.
        if cache.isEmpty {
            migrateFromUserDefaults()
        }
    }

    // MARK: - UserDefaults-compatible API

    func integer(forKey key: String) -> Int {
        Int(cache[key] ?? 0)
    }

    func bool(forKey key: String) -> Bool {
        (cache[key] ?? 0) != 0
    }

    /// Returns a `Double?` boxed as `Any?` so existing `as? Double` casts work,
    /// and `nil` means "never set" (matching UserDefaults.object semantics).
    func object(forKey key: String) -> Any? {
        cache[key]
    }

    func set(_ value: Int, forKey key: String)    { write(Double(value), key) }
    func set(_ value: Double, forKey key: String) { write(value, key) }
    func set(_ value: Bool, forKey key: String)   { write(value ? 1 : 0, key) }

    // MARK: - Private

    private func write(_ value: Double, _ key: String) {
        cache[key] = value
        persist()
        mirror.set(value, forKey: key)  // keep the cache mirror in sync
    }

    private func persist() {
        UsageStore.writeKeychain(
            cache, account: account, service: service, accessGroup: accessGroup
        )
    }

    private func migrateFromUserDefaults() {
        // Keys whose values must persist across reinstall.
        let intKeys = [
            "usage.screenshotsThisPeriod",
            "usage.enrichmentBalance",
            "usage.categorySuggestionsThisPeriod",
        ]
        let doubleKeys = [
            "usage.periodStartDate",
            "usage.proEnrichmentStartDate",
        ]
        let boolKeys = [
            "usage.hasClaimedFreeEnrichment",
        ]

        var migrated: [String: Double] = [:]
        for k in intKeys where mirror.object(forKey: k) != nil {
            migrated[k] = Double(mirror.integer(forKey: k))
        }
        for k in doubleKeys {
            if let d = mirror.object(forKey: k) as? Double { migrated[k] = d }
        }
        for k in boolKeys where mirror.object(forKey: k) != nil {
            migrated[k] = mirror.bool(forKey: k) ? 1 : 0
        }

        if !migrated.isEmpty {
            cache = migrated
            persist()
        }
    }

    // MARK: - Access-group resolution

    /// Discovers the app's keychain access-group prefix (the Team ID) at runtime
    /// using the classic "bundle seed ID" probe, then appends `suffix` to form the
    /// fully-qualified shared group. Returns `nil` if discovery fails.
    private static func resolveAccessGroup(suffix: String) -> String? {
        let probe: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "accessGroupProbe",
            kSecAttrService as String: "accessGroupProbe",
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        var status = SecItemCopyMatching(probe as CFDictionary, &result)
        if status == errSecItemNotFound {
            status = SecItemAdd(probe as CFDictionary, &result)
        }
        guard status == errSecSuccess,
              let attrs = result as? [String: Any],
              let group = attrs[kSecAttrAccessGroup as String] as? String,
              let prefix = group.components(separatedBy: ".").first
        else { return nil }
        return "\(prefix).\(suffix)"
    }

    // MARK: - Keychain primitives

    private static func query(account: String, service: String, accessGroup: String?) -> [String: Any] {
        var q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
        ]
        if let accessGroup { q[kSecAttrAccessGroup as String] = accessGroup }
        return q
    }

    private static func readKeychain(account: String, service: String, accessGroup: String?) -> [String: Double]? {
        var q = query(account: account, service: service, accessGroup: accessGroup)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(q as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let dict = try? JSONDecoder().decode([String: Double].self, from: data)
        else { return nil }
        return dict
    }

    private static func writeKeychain(_ dict: [String: Double], account: String, service: String, accessGroup: String?) {
        guard let data = try? JSONEncoder().encode(dict) else { return }
        let q = query(account: account, service: service, accessGroup: accessGroup)

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let status = SecItemUpdate(q as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = q
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(insert as CFDictionary, nil)
        }
    }
}

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
        } catch {
            // non-critical: legacy directory cleanup failed
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
