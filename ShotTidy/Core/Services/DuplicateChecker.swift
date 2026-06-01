//
//  DuplicateChecker.swift
//  ShotTidy
//
//  Utility for detecting duplicate CatalogItems before saving.
//
//  Matching rules:
//    - Title match is required (case-insensitive, whitespace-trimmed).
//    - Confidence is boosted to `.high` when subtitle or link also matches.
//    - Duplicates are always checked within the same category only.
//

import SwiftUI
import SwiftData

// MARK: - Duplicate Confidence

/// Describes how confidently an existing item is considered a duplicate.
enum DuplicateConfidence {
    /// Title matches AND at least one of subtitle or link also matches.
    case high
    /// Title matches only (case-insensitive).
    case medium

    var label: String {
        switch self {
        case .high:   return "Likely duplicate"
        case .medium: return "Possible duplicate"
        }
    }

    var icon: String {
        switch self {
        case .high:   return "exclamationmark.2.circle.fill"
        case .medium: return "exclamationmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .high:   return .red
        case .medium: return .orange
        }
    }
}

// MARK: - Duplicate Match

/// An existing catalog item that may be a duplicate of the item being created/edited.
struct DuplicateMatch: Identifiable {
    let id = UUID()
    let item: CatalogItem
    let confidence: DuplicateConfidence
    /// Human-readable names of the fields that matched, e.g. ["Title", "Link"].
    let matchedFields: [String]

    var reason: String {
        matchedFields.joined(separator: " + ")
    }
}

// MARK: - DuplicateChecker

enum DuplicateChecker {

    /// Find existing `CatalogItem`s that may be duplicates of the given values.
    ///
    /// - Parameters:
    ///   - title:       The title to check (required; empty string returns `[]`).
    ///   - subtitle:    Optional subtitle (e.g. price, author, address).
    ///   - link:        Optional URL or email.
    ///   - categoryKey: Only items whose `categoryRaw` matches are searched.
    ///   - excludingId: Pass the current item's `id` when editing to skip itself.
    ///   - context:     A SwiftData `ModelContext` to query.
    /// - Returns: Matches sorted by confidence (`.high` first).
    static func findDuplicates(
        for title: String,
        subtitle: String? = nil,
        link: String? = nil,
        categoryKey: String,
        excludingId: UUID? = nil,
        in context: ModelContext
    ) -> [DuplicateMatch] {

        let normalizedTitle = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalizedTitle.isEmpty else { return [] }

        let categoryRaw = categoryKey
        let descriptor = FetchDescriptor<CatalogItem>(
            predicate: #Predicate { $0.categoryRaw == categoryRaw }
        )
        guard let items = try? context.fetch(descriptor) else { return [] }

        var matches: [DuplicateMatch] = []

        for item in items {
            // Skip the item being edited
            if let eid = excludingId, item.id == eid { continue }

            let itemTitle = item.title
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            // Title is required for any match
            guard itemTitle == normalizedTitle else { continue }

            var matchedFields: [String] = ["Title"]
            var confidence: DuplicateConfidence = .medium

            // Subtitle match → boost confidence
            let normalizedSub = subtitle?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            let itemSub = item.subtitle?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if let s = normalizedSub, let is_ = itemSub,
               !s.isEmpty, !is_.isEmpty, s == is_ {
                matchedFields.append("Subtitle")
                confidence = .high
            }

            // Link match → boost confidence
            let normalizedLink = link?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            let itemLink = item.link?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()
            if let l = normalizedLink, let il = itemLink,
               !l.isEmpty, !il.isEmpty, l == il {
                matchedFields.append("Link")
                confidence = .high
            }

            matches.append(DuplicateMatch(
                item: item,
                confidence: confidence,
                matchedFields: matchedFields
            ))
        }

        // High-confidence matches first
        return matches.sorted {
            $0.confidence == .high && $1.confidence == .medium
        }
    }
}
