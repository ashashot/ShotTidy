//
//  Screenshot.swift
//  ShotTidyMac
//

import Foundation
import SwiftData

enum AnalysisStatus: String, Codable {
    case pending   = "pending"
    case analyzing = "analyzing"
    case done      = "done"
    case failed    = "failed"
}

@Model
final class Screenshot {

    var id: UUID = UUID()

    @Attribute(.externalStorage)
    var thumbnailData: Data? = nil

    var originalFileName: String? = nil
    var createdAt: Date = Date()
    var analyzedAt: Date? = nil

    var analysisStatusRaw: String = AnalysisStatus.pending.rawValue
    var extractedItemsCount: Int = 0
    var errorMessage: String? = nil

    var analysisStatus: AnalysisStatus {
        get { AnalysisStatus(rawValue: analysisStatusRaw) ?? .pending }
        set { analysisStatusRaw = newValue.rawValue }
    }

    init() {}
}
