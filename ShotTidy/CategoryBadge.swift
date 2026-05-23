//
//  CategoryBadge.swift
//  ShotTidy
//
//  Цветной бейдж категории.
//

import SwiftUI

struct CategoryBadge: View {
    let category: String?

    private var cat: ScreenshotCategory {
        guard let c = category else { return .other }
        return ScreenshotCategory(rawValue: c) ?? .other
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: cat.icon)
                .font(.caption2)
            Text(cat.rawValue)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .foregroundStyle(color)
        .clipShape(Capsule())
    }

    private var color: Color {
        switch cat {
        case .uiDesign:      return .purple
        case .development:   return .blue
        case .productivity:  return .green
        case .social:        return .orange
        case .finance:       return Color(UIColor.systemTeal)
        case .education:     return Color(UIColor.systemYellow)
        case .entertainment: return .red
        case .other:         return .gray
        }
    }
}

#Preview {
    HStack {
        CategoryBadge(category: "UI Design")
        CategoryBadge(category: "Development")
        CategoryBadge(category: "Finance")
    }
    .padding()
}
