//
//  CategoryStyleOptions.swift
//  ShotTidy
//
//  Curated SF Symbols and colors offered when creating a custom category.
//

import SwiftUI

enum CategoryStyleOptions {

    /// Selectable SF Symbols for custom categories (shared with macOS).
    static let icons: [String] = CategoryStyleIcons.all

    /// Selectable colors (stored as hex).
    static let colors: [Color] = [
        .red, .orange, .yellow, .green, .mint,
        .teal, .cyan, .blue, .indigo, .purple,
        .pink, .brown,
        Color(red: 0.18, green: 0.75, blue: 0.35),
        Color(red: 0.0, green: 0.65, blue: 0.85),
        Color(red: 0.48, green: 0.48, blue: 0.56),
    ]

    static let defaultIcon = "tag.fill"
    static let defaultColorHex = "#0A84FF"
}
