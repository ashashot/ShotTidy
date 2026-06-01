//
//  WidgetModels.swift
//  ShotTidyWidget
//
//  Catalog snapshot types shared between the Widget Extension and the main app via
//  App Group JSON. Field names must match WidgetDataManager's nested types in the
//  main target — both sides use synthesised Codable, so the names are the keys.
//

import Foundation

// MARK: - WidgetCatalogItem

struct WidgetCatalogItem: Codable, Identifiable {
    let id: UUID
    let categoryKey: String
    let title: String
    let subtitle: String?
    let isCompleted: Bool
    let createdAt: Date
}

// MARK: - WidgetSnapshot

struct WidgetSnapshot: Codable {
    var items: [WidgetCatalogItem]
    let updatedAt: Date
    let isPro: Bool
    let enrichmentBalance: Int
    let screenshotsThisPeriod: Int

    static let empty = WidgetSnapshot(
        items: [],
        updatedAt: .distantPast,
        isPro: false,
        enrichmentBalance: 0,
        screenshotsThisPeriod: 0
    )
}
