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
    init(
        category: ItemCategory,
        title: String,
        subtitle: String? = nil,
        link: String? = nil,
        extra1: String? = nil,
        extra2: String? = nil,
        notes: String? = nil,
        sourceScreenshotId: UUID? = nil
    ) {
        self.id = UUID()
        self.categoryRaw = category.rawValue
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

    // MARK: - Computed
    var category: ItemCategory {
        get { ItemCategory(rawValue: categoryRaw) ?? .tasks }
        set { categoryRaw = newValue.rawValue }
    }
}
