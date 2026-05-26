//
//  CategoryCardView.swift
//  ShotTidy
//
//  Category card in the main screen grid.
//

import SwiftUI

struct CategoryCardView: View {
    let category: ItemCategory
    let count: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(category.color.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: category.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(category.color)
                }

                Spacer()

                // Counter
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(category.color)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(category.color.opacity(0.12))
                        .clipShape(Capsule())
                }
            }

            Text(category.localizedName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            if count == 0 {
                Text("No items")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            } else {
                Text(count == 1 ? "1 item" : "\(count) items")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(category.color.opacity(0.15), lineWidth: 1)
        )
    }
}

#Preview {
    CategoryCardView(category: .shopping, count: 14)
        .padding()
}
