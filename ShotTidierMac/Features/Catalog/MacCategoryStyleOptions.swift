//
//  MacCategoryStyleOptions.swift
//  ShotTidierMac
//
//  Curated SF Symbols and colors for custom category creation.
//

import SwiftUI

enum MacCategoryStyleOptions {

    static let icons: [String] = CategoryStyleIcons.all

    static let colorHexes: [String] = [
        "#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#00C7BE",
        "#32ADE6", "#007AFF", "#5856D6", "#AF52DE", "#FF2D55",
        "#A2845E", "#30B94D", "#00A3C7", "#8E8E93",
    ]

    static var colors: [Color] { colorHexes.map { Color(hex: $0) } }

    static let defaultIcon = "tag.fill"
    static let defaultColorHex = "#007AFF"
}
