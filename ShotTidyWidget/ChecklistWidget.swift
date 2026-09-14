//
//  ChecklistWidget.swift
//  ShotTidyWidget
//
//  Interactive to-do checklist for Shopping or Tasks (Medium / Large).
//  Checkbox buttons toggle completion via AppIntent without opening the app.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Entry

struct ChecklistEntry: TimelineEntry {
    let date: Date
    let configuration: ChecklistIntent
    let items: [WidgetCatalogItem]
}

// MARK: - Provider

struct ChecklistProvider: AppIntentTimelineProvider {
    typealias Intent = ChecklistIntent
    typealias Entry  = ChecklistEntry

    func placeholder(in context: Context) -> ChecklistEntry {
        ChecklistEntry(date: Date(), configuration: ChecklistIntent(), items: previewItems())
    }

    func snapshot(for configuration: ChecklistIntent, in context: Context) async -> ChecklistEntry {
        makeEntry(configuration: configuration)
    }

    func timeline(for configuration: ChecklistIntent, in context: Context) async -> Timeline<ChecklistEntry> {
        let entry   = makeEntry(configuration: configuration)
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    private func makeEntry(configuration: ChecklistIntent) -> ChecklistEntry {
        let snap          = WidgetDataReader.readSnapshot()
        let key           = configuration.listType.id
        let hideCompleted = WidgetDataReader.hideCompleted(forCategory: key)
        let items = snap.items
            .filter { $0.categoryKey == key }
            .filter { !hideCompleted || !$0.isCompleted }
            .sorted {
                if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
                return $0.createdAt > $1.createdAt
            }
        return ChecklistEntry(date: Date(), configuration: configuration, items: items)
    }

    private func previewItems() -> [WidgetCatalogItem] {
        [
            WidgetCatalogItem(id: UUID(), categoryKey: "tasks", title: "Buy groceries",    subtitle: nil, isCompleted: false, createdAt: Date()),
            WidgetCatalogItem(id: UUID(), categoryKey: "tasks", title: "Call the dentist", subtitle: nil, isCompleted: false, createdAt: Date()),
            WidgetCatalogItem(id: UUID(), categoryKey: "tasks", title: "Review the PR",    subtitle: nil, isCompleted: true,  createdAt: Date()),
        ]
    }
}

// MARK: - Widget

struct ChecklistWidget: Widget {
    let kind = "ChecklistWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ChecklistIntent.self,
            provider: ChecklistProvider()
        ) { entry in
            ChecklistWidgetView(entry: entry)
                .environment(\.locale, WidgetDataReader.resolvedLocale)
                .containerBackground(for: .widget) { Color(.systemBackground) }
        }
        .configurationDisplayName("Checklist")
        .description("Shopping list or tasks with interactive checkboxes.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - View

struct ChecklistWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ChecklistEntry

    private var info: WidgetCategoryInfo {
        WidgetCategoryInfo.forKey(entry.configuration.listType.id)
    }

    private var pendingCount: Int {
        entry.items.filter { !$0.isCompleted }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: WidgetMetrics.headerSpacing(for: family)) {
            WidgetHeader(info: info, badge: pendingCount > 0 ? Text("\(pendingCount) left") : nil)

            if entry.items.isEmpty {
                WidgetEmptyState(systemImage: "checkmark.circle.fill", text: "All done!", color: info.color)
            } else {
                WidgetChecklistContent(info: info, items: entry.items, showsSubtitle: false)
            }
        }
        .widgetURL(URL(string: "shottidy://category/\(entry.configuration.listType.id)"))
    }
}
