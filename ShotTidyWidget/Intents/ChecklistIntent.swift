//
//  ChecklistIntent.swift
//  ShotTidyWidget
//
//  AppIntentConfiguration intent for the Checklist widget.
//  Lets users pick Shopping or Tasks in the widget configuration sheet.
//

import AppIntents
import WidgetKit

// MARK: - ChecklistTypeAppEntity

struct ChecklistTypeAppEntity: AppEntity {
    let id: String
    let displayName: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "List Type")
    }

    static var defaultQuery = ChecklistTypeEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource(stringLiteral: displayName))
    }

    static let shopping = ChecklistTypeAppEntity(id: "shopping", displayName: "Shopping")
    static let tasks    = ChecklistTypeAppEntity(id: "tasks",    displayName: "Tasks")
}

// MARK: - ChecklistTypeEntityQuery

struct ChecklistTypeEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [ChecklistTypeAppEntity] {
        [.shopping, .tasks].filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [ChecklistTypeAppEntity] { [.shopping, .tasks] }

    func defaultResult() async -> ChecklistTypeAppEntity? { .tasks }
}

// MARK: - ChecklistIntent

struct ChecklistIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource       = "Checklist"
    static var description = IntentDescription("Choose Shopping or Tasks")

    @Parameter(title: "List Type", default: ChecklistTypeAppEntity.tasks)
    var listType: ChecklistTypeAppEntity

    init() { self.listType = .tasks }
    init(listType: ChecklistTypeAppEntity) { self.listType = listType }
}
