//
//  Screenshot.swift
//  ShotTidy
//
//  SwiftData model for storing source screenshots (backup copy).
//  All fields are Optional or have defaults — required by CloudKit.
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

    /// Thumbnail stored in external storage — does not bloat the database
    @Attribute(.externalStorage)
    var thumbnailData: Data? = nil

    var originalFileName: String? = nil
    var createdAt: Date = Date()
    var analyzedAt: Date? = nil

    /// Analysis status
    var analysisStatusRaw: String = AnalysisStatus.pending.rawValue

    /// Number of catalog items extracted from this screenshot
    var extractedItemsCount: Int = 0

    /// Analysis error message
    var errorMessage: String? = nil

    // MARK: - Computed

    var analysisStatus: AnalysisStatus {
        get { AnalysisStatus(rawValue: analysisStatusRaw) ?? .pending }
        set { analysisStatusRaw = newValue.rawValue }
    }

    // MARK: - Init

    init() {}
}
