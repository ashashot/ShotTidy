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

    private var pendingCount: Int {
        entry.items.filter { !$0.isCompleted }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: WidgetMetrics.headerSpacing(for: family)) {
            WidgetHeader(info: info, badge: pendingCount > 0 ? Text("\(pendingCount) to buy") : nil)

            if entry.items.isEmpty {
                WidgetEmptyState(systemImage: "cart.badge.plus", text: "Wishlist is empty", color: info.color)
            } else {
                WidgetChecklistContent(info: info, items: entry.items, showsSubtitle: true)
            }
        }
        .widgetURL(URL(string: "shottidy://category/shopping"))
    }
}
