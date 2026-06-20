//
//  DraftItem.swift
//  ShotTidyMac
//

import Foundation

struct DraftItem: Identifiable, Equatable {
    var id = UUID()
    var categoryKey: String
    var isSelected: Bool = true

    var title: String = ""
    var subtitle: String = ""
    var link: String = ""
    var extra1: String = ""
    var extra2: String = ""
    var notes: String = ""

    var suggestedCategoryName: String = ""
    var sourceScreenshotId: UUID? = nil

    static let newCategoryKey = "__new__"
    var needsNewCategory: Bool { categoryKey == DraftItem.newCategoryKey }

    init(
        category: ItemCategory,
        isSelected: Bool = true,
        title: String = "",
        subtitle: String = "",
        link: String = "",
        extra1: String = "",
        extra2: String = "",
        notes: String = "",
        sourceScreenshotId: UUID? = nil
    ) {
        self.categoryKey = category.rawValue
        self.isSelected = isSelected
        self.title = title
        self.subtitle = subtitle
        self.link = link
        self.extra1 = extra1
        self.extra2 = extra2
        self.notes = notes
        self.sourceScreenshotId = sourceScreenshotId
    }

    init(
        categoryKey: String,
        isSelected: Bool = true,
        title: String = "",
        subtitle: String = "",
        link: String = "",
        extra1: String = "",
        extra2: String = "",
        notes: String = "",
        suggestedCategoryName: String = "",
        sourceScreenshotId: UUID? = nil
    ) {
        self.categoryKey = categoryKey
        self.isSelected = isSelected
        self.title = title
        self.subtitle = subtitle
        self.link = link
        self.extra1 = extra1
        self.extra2 = extra2
        self.notes = notes
        self.suggestedCategoryName = suggestedCategoryName
        self.sourceScreenshotId = sourceScreenshotId
    }

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Untitled" : trimmed
    }

    func toCatalogItem(overrideKey: String? = nil) -> CatalogItem {
        CatalogItem(
            categoryKey: overrideKey ?? categoryKey,
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
