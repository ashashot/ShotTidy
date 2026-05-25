//
//  AppGroupManager.swift
//  ShotTidy
//
//  Shared container between the main app and the Share Extension.
//  Add this file to both targets: ShotTidy and ShotTidyShare.
//

import Foundation

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

// MARK: - AppGroupManager

enum AppGroupManager {
    static let groupID = "group.mbx.ShotTidy"

    /// URL of the shared App Group container
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
    }

    /// Directory for raw images pending analysis (legacy flow)
    static var pendingImagesDir: URL? {
        containerURL?.appendingPathComponent("PendingImages", isDirectory: true)
    }

    /// File URL for pending draft items JSON (new share extension flow)
    private static var pendingDraftsURL: URL? {
        containerURL?.appendingPathComponent("pending_drafts.json")
    }

    // MARK: - API Key (UserDefaults in App Group, so Share Extension can read it)

    static var apiKey: String? {
        get { UserDefaults(suiteName: groupID)?.string(forKey: "openai_api_key") }
        set { UserDefaults(suiteName: groupID)?.set(newValue, forKey: "openai_api_key") }
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

    // MARK: - Pending Raw Images (legacy flow)

    /// Save an image to the analysis queue
    @discardableResult
    static func savePendingImage(_ data: Data) throws -> URL {
        guard let dir = pendingImagesDir else {
            throw AppGroupError.containerUnavailable
        }
        try FileManager.default.createDirectory(
            at: dir,
            withIntermediateDirectories: true,
            attributes: nil
        )
        let fileURL = dir.appendingPathComponent("\(UUID().uuidString).jpg")
        try data.write(to: fileURL)
        return fileURL
    }

    /// URLs of all pending raw images
    static func pendingImageURLs() -> [URL] {
        guard let dir = pendingImagesDir,
              FileManager.default.fileExists(atPath: dir.path) else { return [] }
        return (try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )) ?? []
    }

    /// Delete a processed raw image file
    static func deletePendingImage(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}

// MARK: - Errors

enum AppGroupError: LocalizedError {
    case containerUnavailable

    var errorDescription: String? {
        "The App Group shared container is unavailable. Check the group.mbx.ShotTidy configuration."
    }
}
