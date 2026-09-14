//
//  CategoryListWidget.swift
//  ShotTidyWidget
//
//  Displays items from a user-selected category.
//  Small: up to 3 items. Medium: up to 4. Large: up to 8 + plan footer.
//  The row count adapts down (ViewThatFits) so nothing is clipped.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Entry

struct CategoryListEntry: TimelineEntry {
    let date: Date
    let configuration: CategoryListIntent
    let items: [WidgetCatalogItem]
    let isPro: Bool
    let enrichmentBalance: Int
}

// MARK: - Provider

struct CategoryListProvider: AppIntentTimelineProvider {
    typealias Intent = CategoryListIntent
    typealias Entry  = CategoryListEntry

    func placeholder(in context: Context) -> CategoryListEntry {
        CategoryListEntry(
            date: Date(),
            configuration: CategoryListIntent(),
            items: previewItems(categoryKey: "shopping"),
            isPro: false,
            enrichmentBalance: 0
        )
    }

    func snapshot(for configuration: CategoryListIntent, in context: Context) async -> CategoryListEntry {
        makeEntry(configuration: configuration)
    }

    func timeline(for configuration: CategoryListIntent, in context: Context) async -> Timeline<CategoryListEntry> {
        let entry   = makeEntry(configuration: configuration)
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        return Timeline(entries: [entry], policy: .after(refresh))
    }

    private func makeEntry(configuration: CategoryListIntent) -> CategoryListEntry {
        let snap  = WidgetDataReader.readSnapshot()
        let key   = configuration.category.id
        let items = snap.items
            .filter { $0.categoryKey == key }
            .sorted { $0.createdAt > $1.createdAt }
        return CategoryListEntry(
            date: Date(),
            configuration: configuration,
            items: items,
            isPro: snap.isPro,
            enrichmentBalance: snap.enrichmentBalance
        )
    }

    private func previewItems(categoryKey: String) -> [WidgetCatalogItem] {
        [
            WidgetCatalogItem(id: UUID(), categoryKey: categoryKey, title: "Nike Air Max 270",    subtitle: "$129",  isCompleted: false, createdAt: Date()),
            WidgetCatalogItem(id: UUID(), categoryKey: categoryKey, title: "Mechanical Keyboard",  subtitle: "$89",   isCompleted: false, createdAt: Date()),
            WidgetCatalogItem(id: UUID(), categoryKey: categoryKey, title: "Wireless Headphones",  subtitle: "$249",  isCompleted: true,  createdAt: Date()),
        ]
    }
}

// MARK: - Widget

struct CategoryListWidget: Widget {
    let kind = "CategoryListWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: CategoryListIntent.self,
            provider: CategoryListProvider()
        ) { entry in
            CategoryListWidgetView(entry: entry)
                .environment(\.locale, WidgetDataReader.resolvedLocale)
                .containerBackground(for: .widget) { Color(.systemBackground) }
        }
        .configurationDisplayName("Category List")
        .description("Shows items from the category you choose.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - View

struct CategoryListWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CategoryListEntry

    private var info: WidgetCategoryInfo {
        WidgetCategoryInfo.forKey(entry.configuration.category.id)
    }

    /// Row budgets tried in order; the first one that fits the height wins.
    private var rowBudgets: [Int] {
        switch family {
        case .systemSmall:  return [3, 2]
        case .systemMedium: return [4, 3, 2]
        default:            return [8, 7, 6, 5]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: WidgetMetrics.headerSpacing(for: family)) {
            WidgetHeader(info: info, badge: Text("\(entry.items.count)"))

            if entry.items.isEmpty {
                WidgetEmptyState(systemImage: info.iconName, text: "No items yet", color: info.color)
            } else {
                ViewThatFits(in: .vertical) {
                    ForEach(rowBudgets, id: \.self) { budget in
                        itemList(maxVisible: budget)
                    }
                }
            }

            if family == .systemLarge {
                planFooter
            }
        }
        .widgetURL(URL(string: "shottidy://category/\(entry.configuration.category.id)"))
    }

    // MARK: Subviews

    private func itemList(maxVisible: Int) -> some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 4 : 5) {
            ForEach(entry.items.prefix(maxVisible)) { item in
                HStack(spacing: 6) {
                    Circle()
                        .fill(item.isCompleted ? info.color : info.color.opacity(0.25))
                        .frame(width: 5, height: 5)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.title)
                            .font(.system(size: WidgetMetrics.rowTextSize(for: family), weight: .medium))
                            .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)
                            .strikethrough(item.isCompleted, color: .secondary)
                            .lineLimit(1)
                        if let sub = item.subtitle, !sub.isEmpty, family == .systemLarge {
                            Text(sub)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
            if entry.items.count > maxVisible {
                WidgetOverflowLabel(count: entry.items.count - maxVisible)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var planFooter: some View {
        Divider()
        HStack {
            if entry.isPro {
                Label("Pro", systemImage: "crown.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.orange)
            } else {
                Label("Free", systemImage: "person.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if entry.enrichmentBalance > 0 {
                Label("\(entry.enrichmentBalance) credits", systemImage: "magnifyingglass")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 4)
    }
}
