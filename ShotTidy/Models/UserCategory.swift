//
//  UserCategory.swift
//  ShotTidy
//
//  SwiftData model for user-defined catalog categories (Pro feature).
//  Mirrors the data carried by the built-in `ItemCategory` enum so both
//  can be projected into a common `CategoryDescriptor`.
//
//  All properties have defaults — required for CloudKit syncing.
//  Custom keys are prefixed with `custom_` so they never collide with
//  the built-in `ItemCategory` raw values.
//

import Foundation
import SwiftData

@Model
final class UserCategory {

    // MARK: - Identity
    /// Stable key stored in `CatalogItem.categoryRaw`. Format: "custom_<uuid>".
    var key: String = ""
    var name: String = ""

    // MARK: - Appearance
    var iconName: String = "tag.fill"
    var colorHex: String = "#8E8E93"

    // MARK: - Ordering / metadata
    var sortOrder: Int = 0
    var createdAt: Date = Date()

    /// Optional hint passed to the AI so it knows when to match this category.
    var aiHint: String = ""

    // MARK: - Field labels (universal schema)
    // An empty label means the field is hidden for this category.
    // `titleLabel` is always shown (falls back to "Title" if empty).
    var titleLabel: String = "Title"
    var subtitleLabel: String = ""
    var linkLabel: String = ""
    var extra1Label: String = ""
    var extra2Label: String = ""
    var notesLabel: String = ""

    // MARK: - Init

    init(
        key: String = UserCategory.makeKey(),
        name: String,
        iconName: String = "tag.fill",
        colorHex: String = "#8E8E93",
        sortOrder: Int = 0,
        aiHint: String = "",
        titleLabel: String = "Title",
        subtitleLabel: String = "",
        linkLabel: String = "",
        extra1Label: String = "",
        extra2Label: String = "",
        notesLabel: String = ""
    ) {
        self.key = key
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.aiHint = aiHint
        self.titleLabel = titleLabel
        self.subtitleLabel = subtitleLabel
        self.linkLabel = linkLabel
        self.extra1Label = extra1Label
        self.extra2Label = extra2Label
        self.notesLabel = notesLabel
    }

    // MARK: - Key generation

    /// Generates a unique, collision-free key for a custom category.
    static func makeKey() -> String {
        "custom_\(UUID().uuidString.lowercased())"
    }

    /// True when a raw category key belongs to a custom (user-defined) category.
    static func isCustomKey(_ key: String) -> Bool {
        key.hasPrefix("custom_")
    }
}
