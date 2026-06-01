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
        let snap  = WidgetDataReader.readSnapshot()
        let key   = configuration.listType.id
        let items = snap.items
            .filter { $0.categoryKey == key }
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

    private var maxPending: Int   { family == .systemLarge ? 9 : 4 }
    private var maxCompleted: Int { family == .systemLarge ? 3 : 1 }

    private var pendingItems: [WidgetCatalogItem] {
        Array(entry.items.filter { !$0.isCompleted }.prefix(maxPending))
    }

    private var completedItems: [WidgetCatalogItem] {
        Array(entry.items.filter { $0.isCompleted }.prefix(maxCompleted))
    }

    private var pendingCount: Int {
        entry.items.filter { !$0.isCompleted }.count
    }

    private var outerPadding: CGFloat { family == .systemLarge ? 16 : 13 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView.padding(.bottom, 8)

            if entry.items.isEmpty {
                allDoneView
            } else {
                listView
            }
        }
        .padding(outerPadding)
        .widgetURL(URL(string: "shottidy://category/\(entry.configuration.listType.id)"))
    }

    // MARK: Subviews

    private var headerView: some View {
        HStack(spacing: 6) {
            Image(systemName: info.iconName)
                .font(.system(size: 14, weight: .semibold))
            Text(info.displayName)
                .font(.system(size: 14, weight: .semibold))
            Spacer()
            if pendingCount > 0 {
                Text("\(pendingCount) left")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(info.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(info.color.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .foregroundStyle(info.color)
    }

    private var allDoneView: some View {
        VStack(spacing: 6) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 30))
                .foregroundStyle(info.color.opacity(0.4))
            Text("All done!")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var listView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(pendingItems.enumerated()), id: \.element.id) { idx, item in
                ChecklistRowView(item: item, color: info.color)
                if idx < pendingItems.count - 1 {
                    Divider().padding(.leading, 34)
                }
            }

            if !completedItems.isEmpty {
                Divider().padding(.vertical, 4)
                ForEach(completedItems) { item in
                    ChecklistRowView(item: item, color: info.color)
                }
            }

            let overflow = pendingCount - pendingItems.count
            if overflow > 0 {
                Text("+\(overflow) more")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Row

struct ChecklistRowView: View {
    let item: WidgetCatalogItem
    let color: Color

    var body: some View {
        Button(intent: ToggleCompletionIntent(itemID: item.id)) {
            HStack(spacing: 8) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(item.isCompleted ? color : Color(.tertiaryLabel))
                Text(item.title)
                    .font(.system(size: 13))
                    .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)
                    .strikethrough(item.isCompleted, color: .secondary)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
