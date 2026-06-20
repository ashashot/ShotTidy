//
//  UserCategory.swift
//  ShotTidyMac
//

import Foundation
import SwiftData

@Model
final class UserCategory {

    var key: String = ""
    var name: String = ""
    var iconName: String = "tag.fill"
    var colorHex: String = "#8E8E93"
    var sortOrder: Int = 0
    var createdAt: Date = Date()
    var aiHint: String = ""

    var titleLabel: String = "Title"
    var subtitleLabel: String = ""
    var linkLabel: String = ""
    var extra1Label: String = ""
    var extra2Label: String = ""
    var notesLabel: String = ""

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

    static func makeKey() -> String {
        "custom_\(UUID().uuidString.lowercased())"
    }

    static func isCustomKey(_ key: String) -> Bool {
        key.hasPrefix("custom_")
    }
}
