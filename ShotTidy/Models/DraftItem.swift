//
//  DraftItem.swift
//  ShotTidy
//
//  A draft item pending user confirmation.
//  Used on the confirmation screen after AI analysis.
//
//  `categoryKey` holds either a built-in `ItemCategory` raw value or a custom
//  `UserCategory.key`. The special value `DraftItem.newCategoryKey` marks a
//  draft the AI thinks needs a brand-new category (see `suggestedCategoryName`).
//

import Foundation

struct DraftItem: Identifiable, Equatable {
    var id = UUID()

    /// Built-in raw value, custom category key, or `newCategoryKey` placeholder.
    var categoryKey: String
    var isSelected: Bool = true

    var title: String = ""
    var subtitle: String = ""
    var link: String = ""
    var extra1: String = ""
    var extra2: String = ""
    var notes: String = ""

    /// Name the AI proposed when nothing matched — only set for `newCategoryKey` drafts.
    var suggestedCategoryName: String = ""

    var sourceScreenshotId: UUID? = nil

    // MARK: - Special keys

    /// Placeholder key for a draft that needs a new custom category.
    static let newCategoryKey = "__new__"

    /// True when this draft asks the user to create a new category.
    var needsNewCategory: Bool { categoryKey == DraftItem.newCategoryKey }

    // MARK: - Convenience init (built-in category)

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

    // MARK: - Designated init (any key)

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

    // MARK: - Validation
    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? String(localized: "Untitled", bundle: AppLocale.bundle) : trimmed
    }

    // MARK: - Convert to CatalogItem

    /// Builds a CatalogItem using the resolved category key.
    /// Pass `overrideKey` when a `newCategoryKey` draft has just been assigned
    /// to a freshly created custom category.
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
