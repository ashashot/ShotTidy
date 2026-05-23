//
//  Screenshot.swift
//  ShotTidy
//
//  SwiftData модель. Все поля Optional — требование CloudKit.
//

import Foundation
import SwiftData

// MARK: - AnalysisStatus

enum AnalysisStatus: String, Codable {
    case pending    = "pending"
    case analyzing  = "analyzing"
    case done       = "done"
    case failed     = "failed"
}

// MARK: - Screenshot Model

@Model
final class Screenshot {

    // MARK: Идентификатор
    var id: UUID = UUID()

    // MARK: Изображение (миниатюра 300×300, хранится локально и в CloudKit)
    var thumbnailData: Data? = nil

    // MARK: Метаданные файла
    var originalFileName: String? = nil
    var createdAt: Date = Date()
    var analyzedAt: Date? = nil

    // MARK: Результаты AI-анализа (синхронизируются через CloudKit)
    var appName: String? = nil
    var summary: String? = nil
    var category: String? = nil
    var mainIdea: String? = nil
    var rawAnalysis: String? = nil
    var errorMessage: String? = nil

    /// Теги хранятся как строка через запятую (совместимость с CloudKit)
    var tagsRaw: String? = nil

    /// Статус анализа хранится как строка (CloudKit не поддерживает enum)
    var analysisStatusRaw: String = AnalysisStatus.pending.rawValue

    // MARK: Вычисляемые свойства

    var tags: [String] {
        get {
            guard let raw = tagsRaw, !raw.isEmpty else { return [] }
            return raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        }
        set {
            tagsRaw = newValue.joined(separator: ", ")
        }
    }

    var analysisStatus: AnalysisStatus {
        get { AnalysisStatus(rawValue: analysisStatusRaw) ?? .pending }
        set { analysisStatusRaw = newValue.rawValue }
    }

    // MARK: Init

    init() {}
}

// MARK: - Category

enum ScreenshotCategory: String, CaseIterable {
    case uiDesign      = "UI Design"
    case development   = "Development"
    case productivity  = "Productivity"
    case social        = "Social"
    case finance       = "Finance"
    case education     = "Education"
    case entertainment = "Entertainment"
    case other         = "Other"

    var icon: String {
        switch self {
        case .uiDesign:      return "paintbrush"
        case .development:   return "chevron.left.forwardslash.chevron.right"
        case .productivity:  return "checkmark.circle"
        case .social:        return "person.2"
        case .finance:       return "dollarsign.circle"
        case .education:     return "graduationcap"
        case .entertainment: return "play.circle"
        case .other:         return "square.grid.2x2"
        }
    }

    var color: String {
        switch self {
        case .uiDesign:      return "purple"
        case .development:   return "blue"
        case .productivity:  return "green"
        case .social:        return "orange"
        case .finance:       return "mint"
        case .education:     return "yellow"
        case .entertainment: return "red"
        case .other:         return "gray"
        }
    }
}
