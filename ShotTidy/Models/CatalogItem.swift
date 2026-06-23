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

    // MARK: - Calendar

    /// Extracts a parseable date from any text field of the item.
    /// Returns nil when no date-like string is found.
    var calendarDate: Date? {
        // For tasks, subtitle is the dedicated "Due Date" field — check it first
        var candidates: [String?] = []
        if categoryRaw == ItemCategory.tasks.rawValue {
            candidates = [subtitle, notes, extra1]
        } else {
            candidates = [subtitle, extra1, notes]
        }
        let text = candidates.compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        guard !text.isEmpty,
              let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        else { return nil }

        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, range: range)
        let cutoff = Date().addingTimeInterval(-86400 * 365 * 2) // 2 years ago
        return matches.compactMap { $0.date }.first { $0 > cutoff }
    }

    /// Formats all non-empty fields as a multi-line string for use in calendar event notes.
    var calendarEventNotes: String {
        let schema = category.fieldSchema
        var parts: [String] = []
        if let v = subtitle, !v.isEmpty  { parts.append("\(schema.subtitleLabel ?? "Details"): \(v)") }
        if let v = link,     !v.isEmpty  { parts.append("\(schema.linkLabel ?? "Link"): \(v)") }
        if let v = extra1,   !v.isEmpty  { parts.append("\(schema.extra1Label ?? ""): \(v)".trimmingCharacters(in: .whitespaces)) }
        if let v = extra2,   !v.isEmpty  { parts.append("\(schema.extra2Label ?? ""): \(v)".trimmingCharacters(in: .whitespaces)) }
        if let v = notes,    !v.isEmpty  { parts.append("\(schema.notesLabel ?? "Notes"): \(v)") }
        return parts.filter { !$0.hasPrefix(": ") }.joined(separator: "\n")
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
