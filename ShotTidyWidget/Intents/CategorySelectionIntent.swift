//
//  CategorySelectionIntent.swift
//  ShotTidyWidget
//
//  AppIntentConfiguration intent for the Category List widget.
//  Lets users pick which category to display from the widget configuration sheet.
//

import AppIntents
import WidgetKit

// MARK: - CategoryAppEntity

struct CategoryAppEntity: AppEntity {
    let id: String
    let displayName: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Category")
    }

    static var defaultQuery = CategoryEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: LocalizedStringResource(stringLiteral: displayName),
            image: .init(systemName: WidgetCategoryInfo.forKey(id).iconName)
        )
    }

    static let defaultValue = CategoryAppEntity(id: "tasks", displayName: "Tasks")
}

// MARK: - CategoryEntityQuery

struct CategoryEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CategoryAppEntity] {
        WidgetCategoryInfo.allBuiltIn()
            .filter { identifiers.contains($0.key) }
            .map { CategoryAppEntity(id: $0.key, displayName: $0.info.displayName) }
    }

    func suggestedEntities() async throws -> [CategoryAppEntity] {
        WidgetCategoryInfo.allBuiltIn()
            .map { CategoryAppEntity(id: $0.key, displayName: $0.info.displayName) }
    }

    func defaultResult() async -> CategoryAppEntity? { .defaultValue }
}

// MARK: - CategoryListIntent

struct CategoryListIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource       = "Category List"
    static var description = IntentDescription("Choose which category to show")

    @Parameter(title: "Category", default: CategoryAppEntity.defaultValue)
    var category: CategoryAppEntity

    init() { self.category = .defaultValue }
    init(category: CategoryAppEntity) { self.category = category }
}
