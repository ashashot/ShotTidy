//
//  WidgetCategoryInfo.swift
//  ShotTidyWidget
//
//  Lightweight category display metadata for the Widget Extension.
//  Mirrors icon / color / name data from ItemCategory in the main target.
//

import SwiftUI

struct WidgetCategoryInfo {
    let displayName: String
    let iconName: String
    let color: Color

    // MARK: - Built-in lookup table

    private static let all: [String: WidgetCategoryInfo] = [
        "shopping":         .init(displayName: "Shopping",          iconName: "cart.fill",             color: .orange),
        "places":           .init(displayName: "Places",            iconName: "mappin.circle.fill",    color: Color(red: 0.88, green: 0.18, blue: 0.18)),
        "appsServices":     .init(displayName: "Apps & Services",   iconName: "app.fill",              color: .blue),
        "languageLearning": .init(displayName: "Language Learning", iconName: "textformat.abc",        color: Color(red: 0.18, green: 0.75, blue: 0.35)),
        "prompts":          .init(displayName: "Prompts",           iconName: "text.bubble.fill",      color: .purple),
        "health":           .init(displayName: "Health",            iconName: "heart.fill",            color: .pink),
        "recipes":          .init(displayName: "Recipes",           iconName: "fork.knife",            color: Color(red: 0.92, green: 0.67, blue: 0.12)),
        "books":            .init(displayName: "Books",             iconName: "book.fill",             color: Color(red: 0.6, green: 0.38, blue: 0.18)),
        "movies":           .init(displayName: "Movies & TV Shows", iconName: "play.rectangle.fill",   color: .indigo),
        "quotes":           .init(displayName: "Quotes",            iconName: "quote.bubble.fill",     color: .teal),
        "articles":         .init(displayName: "Articles",          iconName: "newspaper.fill",        color: Color(red: 0.0, green: 0.65, blue: 0.85)),
        "contacts":         .init(displayName: "Contacts",          iconName: "person.circle.fill",    color: Color(red: 0.12, green: 0.72, blue: 0.72)),
        "tasks":            .init(displayName: "Tasks",             iconName: "checkmark.circle.fill", color: Color(red: 0.48, green: 0.48, blue: 0.56)),
    ]

    static func forKey(_ key: String) -> WidgetCategoryInfo {
        all[key] ?? .init(displayName: key.capitalized, iconName: "folder.fill", color: .gray)
    }

    /// All 13 built-in categories in display order.
    static func allBuiltIn() -> [(key: String, info: WidgetCategoryInfo)] {
        let order = [
            "shopping", "places", "appsServices", "languageLearning", "prompts",
            "health", "recipes", "books", "movies", "quotes", "articles", "contacts", "tasks",
        ]
        return order.compactMap { key in all[key].map { (key, $0) } }
    }
}
