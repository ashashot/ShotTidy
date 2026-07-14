//
//  WidgetCategoryInfo.swift
//  ShotTidyWidget
//
//  Lightweight category display metadata for the Widget Extension.
//  Derives from the shared ItemCategory enum (cross-compiled into this target)
//  so built-in names/icons/colors stay in sync with the main app automatically.
//

import SwiftUI

struct WidgetCategoryInfo {
    let displayName: String
    let iconName: String
    let color: Color

    static func forKey(_ key: String) -> WidgetCategoryInfo {
        guard let category = ItemCategory(rawValue: key) else {
            return .init(displayName: key.capitalized, iconName: "folder.fill", color: .gray)
        }
        return .init(displayName: category.localizedName, iconName: category.icon, color: category.color)
    }

    /// All 13 built-in categories in `ItemCategory`'s declaration order.
    static func allBuiltIn() -> [(key: String, info: WidgetCategoryInfo)] {
        ItemCategory.allCases.map { ($0.rawValue, forKey($0.rawValue)) }
    }
}
