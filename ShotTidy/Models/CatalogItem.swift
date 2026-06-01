//
//  CatalogItem.swift
//  ShotTidy
//
//  Universal SwiftData model for all catalog categories.
//  All fields are Optional or have default values — required by CloudKit.
//

import Foundation
import SwiftData

@Model
final class CatalogItem {

    // MARK: - Identifiers
    var id: UUID = UUID()
    var categoryRaw: String = ""

    // MARK: - Main fields (flexible schema, semantics depend on category)
    var title: String = ""          // Primary field: name, text, person name
    var subtitle: String? = nil     // Secondary: price, address, translation, author
    var link: String? = nil         // URL: link, email, maps
    var extra1: String? = nil       // Extra field 1: store, city, platform, language
    var extra2: String? = nil       // Extra field 2: currency, country, genre, year
    var notes: String? = nil        // Notes, description, steps

    // MARK: - Metadata
    var sourceScreenshotId: UUID? = nil   // Source screenshot
    var createdAt: Date = Date()
    var isCompleted: Bool = false         // Purchased / visited / read / completed

    // MARK: - Convenience init
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

    /// Designated init accepting a raw category key — works for both built-in
    /// (`ItemCategory` raw values) and custom (`UserCategory.key`) categories.
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

    // MARK: - Built-in category helpers

    /// True only for built-in categories that support a completion toggle
    /// (Tasks, Shopping). Safe for custom keys (returns false).
    var isCompletableCategory: Bool {
        categoryRaw == ItemCategory.tasks.rawValue
            || categoryRaw == ItemCategory.shopping.rawValue
    }

    /// Label for the completion toggle, or nil when the category is not completable.
    var completionLabel: String? {
        if categoryRaw == ItemCategory.tasks.rawValue { return "Completed" }
        if categoryRaw == ItemCategory.shopping.rawValue { return "Purchased" }
        return nil
    }

    // MARK: - Computed
    var category: ItemCategory {
        get { ItemCategory(rawValue: categoryRaw) ?? .tasks }
        set { categoryRaw = newValue.rawValue }
    }

    /// Returns true when at least one optional field that is defined in the
    /// category's FieldSchema is empty — meaning enrichment could help.
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
