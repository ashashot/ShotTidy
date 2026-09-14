//
//  WidgetChrome.swift
//  ShotTidyWidget
//
//  Shared building blocks so every widget uses the same header, spacing,
//  badge, empty state and overflow label. Outer insets come from the system
//  content margins (containerBackground on iOS 17+), so views must NOT add
//  their own outer padding — otherwise the insets get doubled.
//

import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Metrics

enum WidgetMetrics {
    /// Space between the header row and the content below it.
    static func headerSpacing(for family: WidgetFamily) -> CGFloat {
        family == .systemSmall ? 6 : 8
    }

    static func titleSize(for family: WidgetFamily) -> CGFloat {
        family == .systemSmall ? 13 : 14
    }

    static func rowTextSize(for family: WidgetFamily) -> CGFloat {
        family == .systemSmall ? 12 : 13
    }
}

// MARK: - Header

/// Category icon + name on the left, an optional tinted capsule badge on the right.
struct WidgetHeader: View {
    @Environment(\.widgetFamily) private var family
    let info: WidgetCategoryInfo
    /// Localized badge text (e.g. "3 left"); pass nil to hide the capsule.
    let badge: Text?

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: info.iconName)
                .font(.system(size: WidgetMetrics.titleSize(for: family) - 1, weight: .semibold))
            Text(info.displayName)
                .font(.system(size: WidgetMetrics.titleSize(for: family), weight: .semibold))
                .lineLimit(1)
            Spacer(minLength: 4)
            if let badge {
                badge
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(info.color.opacity(0.12))
                    .clipShape(Capsule())
            }
        }
        .foregroundStyle(info.color)
    }
}

// MARK: - Empty state

struct WidgetEmptyState: View {
    let systemImage: String
    let text: LocalizedStringKey
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)
            Image(systemName: systemImage)
                .font(.system(size: 28))
                .foregroundStyle(color.opacity(0.35))
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Overflow label

struct WidgetOverflowLabel: View {
    let count: Int

    var body: some View {
        Text("+\(count) more")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .padding(.top, 4)
    }
}

// MARK: - Checklist content (Shopping + Checklist widgets)

/// Interactive check-off list. Picks the largest row budget that fits the
/// available height, so the content never gets clipped at the widget edges.
struct WidgetChecklistContent: View {
    @Environment(\.widgetFamily) private var family
    let info: WidgetCategoryInfo
    let items: [WidgetCatalogItem]
    let showsSubtitle: Bool

    private var pendingCount: Int { items.filter { !$0.isCompleted }.count }

    /// Row budgets tried in order (pending rows, completed rows).
    private var budgets: [(pending: Int, completed: Int)] {
        family == .systemLarge
            ? [(9, 3), (8, 2), (7, 1), (6, 0), (5, 0)]
            : [(4, 1), (3, 1), (3, 0), (2, 0)]
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            ForEach(Array(budgets.enumerated()), id: \.offset) { _, budget in
                list(maxPending: budget.pending, maxCompleted: budget.completed)
            }
        }
    }

    private func list(maxPending: Int, maxCompleted: Int) -> some View {
        let pending   = Array(items.filter { !$0.isCompleted }.prefix(maxPending))
        let completed = Array(items.filter { $0.isCompleted }.prefix(maxCompleted))
        let overflow  = pendingCount - pending.count

        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(pending.enumerated()), id: \.element.id) { idx, item in
                WidgetChecklistRow(item: item, color: info.color, showsSubtitle: showsSubtitle)
                if idx < pending.count - 1 {
                    Divider().padding(.leading, 26)
                }
            }

            if !completed.isEmpty {
                Divider().padding(.vertical, 3)
                ForEach(completed) { item in
                    WidgetChecklistRow(item: item, color: info.color, showsSubtitle: showsSubtitle)
                }
            }

            if overflow > 0 {
                WidgetOverflowLabel(count: overflow)
            }
            Spacer(minLength: 0)
        }
    }
}

struct WidgetChecklistRow: View {
    @Environment(\.widgetFamily) private var family
    let item: WidgetCatalogItem
    let color: Color
    let showsSubtitle: Bool

    var body: some View {
        Button(intent: ToggleCompletionIntent(itemID: item.id)) {
            HStack(spacing: 8) {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(item.isCompleted ? color : Color(.tertiaryLabel))
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(item.title)
                        .font(.system(size: WidgetMetrics.rowTextSize(for: family)))
                        .foregroundStyle(item.isCompleted ? Color.secondary : Color.primary)
                        .strikethrough(item.isCompleted, color: .secondary)
                        .lineLimit(1)
                    if showsSubtitle, let subtitle = item.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
