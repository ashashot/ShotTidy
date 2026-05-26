//
//  DraftItem.swift
//  ShotTidy
//
//  A draft item pending user confirmation.
//  Used on the confirmation screen after AI analysis.
//

import Foundation

struct DraftItem: Identifiable, Equatable {
    var id = UUID()
    var category: ItemCategory
    var isSelected: Bool = true

    var title: String = ""
    var subtitle: String = ""
    var link: String = ""
    var extra1: String = ""
    var extra2: String = ""
    var notes: String = ""

    var sourceScreenshotId: UUID? = nil

    // MARK: - Validation
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled" : trimmed
    }

    var displaySubtitle: String {
        let trimmed = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? category.localizedName : trimmed
    }

    // MARK: - Convert to CatalogItem
    func toCatalogItem() -> CatalogItem {
        CatalogItem(
            category: category,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            subtitle: subtitle.isEmpty ? nil : subtitle,
            link: link.isEmpty ? nil : link,
            extra1: extra1.isEmpty ? nil : extra1,
            extra2: extra2.isEmpty ? nil : extra2,
            notes: notes.isEmpty ? nil : notes,
            sourceScreenshotId: sourceScreenshotId
        )
    }
}
