//
//  CategoryDescriptor.swift
//  ShotTidyMac
//

import SwiftUI

struct CategoryDescriptor: Identifiable, Hashable {
    let key: String
    let name: String
    let iconName: String
    let color: Color
    let isCustom: Bool
    let fieldSchema: ItemCategory.FieldSchema
    let aiHint: String?

    var id: String { key }

    static func == (lhs: CategoryDescriptor, rhs: CategoryDescriptor) -> Bool {
        lhs.key == rhs.key
    }
    func hash(into hasher: inout Hasher) { hasher.combine(key) }
}

// MARK: - Universal field schema builder

extension ItemCategory.FieldSchema {

    static func universal(
        titleLabel: String,
        subtitleLabel: String,
        linkLabel: String,
        extra1Label: String,
        extra2Label: String,
        notesLabel: String
    ) -> ItemCategory.FieldSchema {
        func clean(_ s: String) -> String? {
            let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
        let title = clean(titleLabel) ?? "Title"
        let subtitle = clean(subtitleLabel)
        let link = clean(linkLabel)
        let extra1 = clean(extra1Label)
        let extra2 = clean(extra2Label)
        let notes = clean(notesLabel)

        return ItemCategory.FieldSchema(
            titleLabel: title,
            titlePlaceholder: "Enter \(title.lowercased())",
            subtitleLabel: subtitle,
            subtitlePlaceholder: subtitle,
            linkLabel: link,
            linkPlaceholder: link.map { _ in "https://..." },
            extra1Label: extra1,
            extra1Placeholder: extra1,
            extra2Label: extra2,
            extra2Placeholder: extra2,
            notesLabel: notes,
            notesPlaceholder: notes
        )
    }

    static var fallback: ItemCategory.FieldSchema {
        ItemCategory.FieldSchema(
            titleLabel: "Title", titlePlaceholder: "Title",
            subtitleLabel: "Details", subtitlePlaceholder: "Details",
            linkLabel: "Link", linkPlaceholder: "https://...",
            extra1Label: "Extra", extra1Placeholder: "Extra",
            extra2Label: "Extra 2", extra2Placeholder: "Extra 2",
            notesLabel: "Notes", notesPlaceholder: "Notes"
        )
    }
}

// MARK: - ItemCategory projection

extension ItemCategory {
    var descriptor: CategoryDescriptor {
        CategoryDescriptor(
            key: rawValue,
            name: localizedName,
            iconName: icon,
            color: color,
            isCustom: false,
            fieldSchema: fieldSchema,
            aiHint: nil
        )
    }
}

// MARK: - UserCategory projection

extension UserCategory {
    var descriptor: CategoryDescriptor {
        CategoryDescriptor(
            key: key,
            name: name,
            iconName: iconName,
            color: Color(hex: colorHex),
            isCustom: true,
            fieldSchema: .universal(
                titleLabel: titleLabel,
                subtitleLabel: subtitleLabel,
                linkLabel: linkLabel,
                extra1Label: extra1Label,
                extra2Label: extra2Label,
                notesLabel: notesLabel
            ),
            aiHint: aiHint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : aiHint
        )
    }
}

// MARK: - Unresolved fallback

extension CategoryDescriptor {
    static func unresolved(key: String) -> CategoryDescriptor {
        CategoryDescriptor(
            key: key,
            name: "Other",
            iconName: "tag.fill",
            color: Color.gray,
            isCustom: true,
            fieldSchema: .fallback,
            aiHint: nil
        )
    }
}
