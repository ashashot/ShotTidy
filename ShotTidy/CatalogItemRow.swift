//
//  CatalogItemRow.swift
//  ShotTidy
//
//  Строка элемента в списке категории.
//

import SwiftUI

struct CatalogItemRow: View {
    let item: CatalogItem
    let schema: ItemCategory.FieldSchema

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                // Чекбокс для задач/покупок
                if item.category == .tasks || item.category == .shopping {
                    Image(systemName: item.isCompleted
                          ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isCompleted ? .green : .secondary)
                        .font(.system(size: 16))
                        .onTapGesture { item.isCompleted.toggle() }
                }

                Text(item.title)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(1)
                    .strikethrough(item.isCompleted, color: .secondary)

                Spacer(minLength: 4)

                if item.link != nil {
                    Image(systemName: "link")
                        .font(.caption)
                        .foregroundStyle(.blue.opacity(0.7))
                }
            }

            if let subtitle = item.subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            if let extra1 = item.extra1, !extra1.isEmpty {
                Text(extra1)
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
        .opacity(item.isCompleted ? 0.55 : 1.0)
    }
}
