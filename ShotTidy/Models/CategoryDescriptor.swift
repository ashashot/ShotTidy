//
//  CategoryDescriptor.swift
//  ShotTidy
//
//  A unified, value-type view of a catalog category — produced by both the
//  built-in `ItemCategory` enum and user-defined `UserCategory` models.
//  Views and services depend on this descriptor instead of the enum, so that
//  custom categories are handled uniformly everywhere.
//

import SwiftUI

// MARK: - CategoryDescriptor

struct CategoryDescriptor: Identifiable, Hashable {
    /// Stable key — matches `CatalogItem.categoryRaw`.
    let key: String
    let name: String
    let iconName: String
    let color: Color
    /// True for user-defined categories.
    let isCustom: Bool
    /// Field labels / placeholders driving the edit & detail forms.
    let fieldSchema: ItemCategory.FieldSchema
    /// Optional hint sent to the AI when matching screenshots to this category.
    let aiHint: String?

    var id: String { key }

    // Identity by key only — appearance changes shouldn't break diffing.
    static func == (lhs: CategoryDescriptor, rhs: CategoryDescriptor) -> Bool {
        lhs.key == rhs.key
    }
    func hash(into hasher: inout Hasher) { hasher.combine(key) }
}

// MARK: - Universal field schema builder

extension ItemCategory.FieldSchema {

    /// Builds a schema for a custom category from user-provided field labels.
    /// An empty label hides that field (title always falls back to "Title").
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

    /// Generic fallback schema used when a category key can no longer be resolved
    /// (e.g. its custom category was deleted but items still reference it).
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
            aiHint: aiHint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : aiHint
        )
    }
}

// MARK: - Unresolved fallback

extension CategoryDescriptor {
    /// Descriptor used when a key resolves to neither a built-in nor a known
    /// custom category. Keeps the catalog usable after a category is deleted.
    static func unresolved(key: String) -> CategoryDescriptor {
        CategoryDescriptor(
            key: key,
            name: "Other",
            iconName: "tag.fill",
            color: Color(.systemGray),
            isCustom: true,
            fieldSchema: .fallback,
            aiHint: nil
        )
    }
}
