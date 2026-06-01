//
//  ToggleCompletionIntent.swift
//  ShotTidyWidget
//
//  Interactive AppIntent powering the checkbox buttons in the Checklist widget.
//  Queues the toggle in the App Group so the main app can apply it on foreground.
//

import AppIntents
import WidgetKit

struct ToggleCompletionIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Item"
    static var description = IntentDescription("Marks an item as done or undone")

    @Parameter(title: "Item ID")
    var itemID: String

    init() {}

    init(itemID: UUID) {
        self.itemID = itemID.uuidString
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: itemID) else { return .result() }
        WidgetDataReader.queueToggle(itemID: uuid)
        WidgetCenter.shared.reloadTimelines(ofKind: "ChecklistWidget")
        return .result()
    }
}
