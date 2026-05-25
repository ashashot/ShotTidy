//
//  AppGroupManager.swift
//  ShotTidy
//
//  Shared container between the main app and the Share Extension.
//  Add this file to both targets: ShotTidy and ShotTidyShare.
//

import Foundation
import UIKit

enum AppGroupManager {
    static let groupID = "group.mbx.ShotTidy"

    /// URL of the shared App Group container
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
    }

    /// Directory for images pending analysis
    static var pendingImagesDir: URL? {
        containerURL?.appendingPathComponent("PendingImages", isDirectory: true)
    }

    // MARK: - Write (called from the Share Extension)

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

    // MARK: - Read (called from the main app)

    /// URLs of all pending images
    static func pendingImageURLs() -> [URL] {
        guard let dir = pendingImagesDir,
              FileManager.default.fileExists(atPath: dir.path) else { return [] }
        return (try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )) ?? []
    }

    /// Delete a processed file
    static func deletePendingImage(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}

enum AppGroupError: LocalizedError {
    case containerUnavailable

    var errorDescription: String? {
        "The App Group shared container is unavailable. Check the group.mbx.ShotTidy configuration."
    }
}
