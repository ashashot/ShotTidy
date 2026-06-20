//
//  CatalogItem.swift
//  ShotTidyMac
//

import Foundation
import SwiftData

@Model
final class CatalogItem {

    var id: UUID = UUID()
    var categoryRaw: String = ""

    var title: String = ""
    var subtitle: String? = nil
    var link: String? = nil
    var extra1: String? = nil
    var extra2: String? = nil
    var notes: String? = nil

    var sourceScreenshotId: UUID? = nil
    var createdAt: Date = Date()
    var isCompleted: Bool = false

    convenience init(
        category: ItemCategory,
        title: String,
        subtitle: String? = nil,
        link: String? = nil,
        extra1: String? = nil,
        extra2: String? = nil,
        notes: String? = nil,
        sourceScreenshotId: UUID? = nil
    ) {
        self.init(
            categoryKey: category.rawValue,
            title: title,
            subtitle: subtitle,
            link: link,
            extra1: extra1,
            extra2: extra2,
            notes: notes,
            sourceScreenshotId: sourceScreenshotId
        )
    }

    init(
        categoryKey: String,
        title: String,
        subtitle: String? = nil,
        link: String? = nil,
        extra1: String? = nil,
        extra2: String? = nil,
        notes: String? = nil,
        sourceScreenshotId: UUID? = nil
    ) {
        self.id = UUID()
        self.categoryRaw = categoryKey
        self.title = title
        self.subtitle = subtitle
        self.link = link
        self.extra1 = extra1
        self.extra2 = extra2
        self.notes = notes
        self.sourceScreenshotId = sourceScreenshotId
        self.createdAt = Date()
        self.isCompleted = false
    }

    var isCompletableCategory: Bool {
        categoryRaw == ItemCategory.tasks.rawValue
            || categoryRaw == ItemCategory.shopping.rawValue
    }

    var completionLabel: String? {
        if categoryRaw == ItemCategory.tasks.rawValue { return "Completed" }
        if categoryRaw == ItemCategory.shopping.rawValue { return "Purchased" }
        return nil
    }

    var category: ItemCategory {
        get { ItemCategory(rawValue: categoryRaw) ?? .tasks }
        set { categoryRaw = newValue.rawValue }
    }

    var hasMissingOptionalFields: Bool {
        let schema = category.fieldSchema
        let checks: [(label: String?, value: String?)] = [
            (schema.subtitleLabel, subtitle),
            (schema.linkLabel,     link),
            (schema.extra1Label,   extra1),
            (schema.extra2Label,   extra2),
            (schema.notesLabel,    notes),
        ]
        return checks.contains { label, value in
            label != nil && (value == nil || value!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
    }
}
