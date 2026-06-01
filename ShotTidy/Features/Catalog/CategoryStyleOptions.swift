//
//  CategoryStyleOptions.swift
//  ShotTidy
//
//  Curated SF Symbols and colors offered when creating a custom category.
//

import SwiftUI

enum CategoryStyleOptions {

    /// Selectable SF Symbols for custom categories.
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
