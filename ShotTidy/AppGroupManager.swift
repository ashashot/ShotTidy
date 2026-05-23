//
//  AppGroupManager.swift
//  ShotTidy
//
//  Общий контейнер между основным приложением и Share Extension.
//  Добавь этот файл в оба таргета: ShotTidy и ShotTidyShare.
//

import Foundation
import UIKit

enum AppGroupManager {
    static let groupID = "group.mbx.ShotTidy"

    /// URL общего контейнера App Group
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID)
    }

    /// Папка с изображениями, ожидающими анализа
    static var pendingImagesDir: URL? {
        containerURL?.appendingPathComponent("PendingImages", isDirectory: true)
    }

    // MARK: - Write (вызывается из Share Extension)

    /// Сохранить изображение в очередь для анализа
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

    // MARK: - Read (вызывается из основного приложения)

    /// Список URL всех ожидающих изображений
    static func pendingImageURLs() -> [URL] {
        guard let dir = pendingImagesDir,
              FileManager.default.fileExists(atPath: dir.path) else { return [] }
        return (try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )) ?? []
    }

    /// Удалить обработанный файл
    static func deletePendingImage(at url: URL) {
        try? FileManager.default.removeItem(at: url)
    }
}

enum AppGroupError: LocalizedError {
    case containerUnavailable

    var errorDescription: String? {
        "Общий контейнер App Group недоступен. Проверь настройку group.mbx.ShotTidy."
    }
}
