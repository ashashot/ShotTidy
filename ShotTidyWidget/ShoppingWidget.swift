//
//  ShoppingWidget.swift
//  ShotTidyWidget
//
//  Dedicated shopping list widget — no configuration needed, works out of the box.
//  Interactive checkboxes mark items as Purchased via AppIntent (iOS 17+).
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Entry

struct ShoppingEntry: TimelineEntry {
    let date: Date
    let items: [WidgetCatalogItem]
}

// MARK: - Provider

struct ShoppingProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShoppingEntry {
        ShoppingEntry(date: Date(), items: previewItems())
    }

    func getSnapshot(in context: Context, completion: @escaping (ShoppingEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ShoppingEntry>) -> Void) {
        let entry   = makeEntry()
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func makeEntry() -> ShoppingEntry {
        let hideCompleted = WidgetDataReader.hideCompleted(forCategory: "shopping")
        let items = WidgetDataReader.readSnapshot().items
            .filter { $0.categoryKey == "shopping" }
            .filter { !hideCompleted || !$0.isCompleted }
            .sorted {
                if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
                return $0.createdAt > $1.createdAt
            }
        return ShoppingEntry(date: Date(), items: items)
    }

    private func previewItems() -> [WidgetCatalogItem] {
        [
            WidgetCatalogItem(id: UUID(), categoryKey: "shopping", title: "Nike Air Max 270",    subtitle: "$129", isCompleted: false, createdAt: Date()),
            WidgetCatalogItem(id: UUID(), categoryKey: "shopping", title: "Mechanical Keyboard",  subtitle: "$89",  isCompleted: false, createdAt: Date()),
            WidgetCatalogItem(id: UUID(), categoryKey: "shopping", title: "Wireless Headphones",  subtitle: "$249", isCompleted: true,  createdAt: Date()),
        ]
    }
}

// MARK: - Widget

struct ShoppingWidget: Widget {
    let kind = "ShoppingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShoppingProvider()) { entry in
            ShoppingWidgetView(entry: entry)
                .environment(\.locale, WidgetDataReader.resolvedLocale)
                .containerBackground(for: .widget) { Color(.systemBackground) }
        }
        .configurationDisplayName("Shopping List")
        .description("Your shopping wishlist with interactive checkboxes.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - View

struct ShoppingWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ShoppingEntry

    private let info = WidgetCategoryInfo.forKey("shopping")

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
                emptyState
            } else {
                listView
            }
        }
        .padding(outerPadding)
        .widgetURL(URL(string: "shottidy://category/shopping"))
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
                Text("\(pendingCount) to buy")
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

    private var emptyState: some View {
        VStack(spacing: 6) {
            Spacer()
            Image(systemName: "cart.badge.plus")
                .font(.system(size: 30))
                .foregroundStyle(info.color.opacity(0.35))
            Text("Wishlist is empty")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var listView: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(pendingItems.enumerated()), id: \.element.id) { idx, item in
                ShoppingRowView(item: item, color: info.color)
                if idx < pendingItems.count - 1 {
                    Divider().padding(.leading, 34)
                }
            }

            if !completedItems.isEmpty {
                Divider().padding(.vertical, 4)
                ForEach(completedItems) { item in
                    ShoppingRowView(item: item, color: info.color)
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

struct ShoppingRowView: View {
    let item: WidgetCatalogItem
    let color: Color

    var body: some View {
        Button(intent: ToggleCompletionIntent(itemID: item.id)) {
            HStack(spacing: 8) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(item.isCompleted ? color : Color(.tertiaryLabel))
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(item.title)
                        .font(.system(size: 13))
                        .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)
                        .strikethrough(item.isCompleted, color: .secondary)
                        .lineLimit(1)
                    if let price = item.subtitle, !price.isEmpty {
                        Text(price)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
