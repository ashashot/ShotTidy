//
//  Screenshot.swift
//  ShotTidy
//
//  SwiftData модель для хранения скриншотов-источников (резервная копия).
//  Все поля Optional или с дефолтом — требование CloudKit.
//

import Foundation
import SwiftData

// MARK: - AnalysisStatus

enum AnalysisStatus: String, Codable {
    case pending   = "pending"
    case analyzing = "analyzing"
    case done      = "done"
    case failed    = "failed"
}

// MARK: - Screenshot Model

@Model
final class Screenshot {

    var id: UUID = UUID()

    /// Миниатюра (хранится в external storage — не нагружает БД)
    @Attribute(.externalStorage)
    var thumbnailData: Data? = nil

    var originalFileName: String? = nil
    var createdAt: Date = Date()
    var analyzedAt: Date? = nil

    /// Статус анализа
    var analysisStatusRaw: String = AnalysisStatus.pending.rawValue

    /// Сколько элементов каталога было извлечено из этого скриншота
    var extractedItemsCount: Int = 0

    /// Сообщение об ошибке анализа
    var errorMessage: String? = nil

    // MARK: - Computed

    var analysisStatus: AnalysisStatus {
        get { AnalysisStatus(rawValue: analysisStatusRaw) ?? .pending }
        set { analysisStatusRaw = newValue.rawValue }
    }

    // MARK: - Init

    init() {}
}
