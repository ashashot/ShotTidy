//
//  MacCategoryStyleOptions.swift
//  ShotTidyMac
//
//  Curated SF Symbols and colors for custom category creation.
//

import SwiftUI

enum MacCategoryStyleOptions {

    static let icons: [String] = [
        "tag.fill", "star.fill", "heart.fill", "flag.fill", "bookmark.fill",
        "wineglass.fill", "cup.and.saucer.fill", "fork.knife", "birthday.cake.fill", "carrot.fill",
        "dumbbell.fill", "figure.run", "bicycle", "sportscourt.fill", "trophy.fill",
        "pawprint.fill", "leaf.fill", "tree.fill", "camera.fill", "music.note",
        "gamecontroller.fill", "paintbrush.fill", "hammer.fill", "wrench.and.screwdriver.fill", "lightbulb.fill",
        "airplane", "car.fill", "house.fill", "building.2.fill", "globe",
        "gift.fill", "creditcard.fill", "bag.fill", "shippingbox.fill", "key.fill",
        "graduationcap.fill", "briefcase.fill", "stethoscope", "pills.fill", "cross.case.fill",
        "tshirt.fill", "eyeglasses", "scissors", "comb.fill", "sparkles",
    ]

    static let colorHexes: [String] = [
        "#FF3B30", "#FF9500", "#FFCC00", "#34C759", "#00C7BE",
        "#32ADE6", "#007AFF", "#5856D6", "#AF52DE", "#FF2D55",
        "#A2845E", "#30B94D", "#00A3C7", "#8E8E93",
    ]

    static var colors: [Color] { colorHexes.map { Color(hex: $0) } }

    static let defaultIcon = "tag.fill"
    static let defaultColorHex = "#007AFF"
}
