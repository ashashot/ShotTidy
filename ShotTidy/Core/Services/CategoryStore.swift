//
//  CategoryStore.swift
//  ShotTidy
//
//  Single source of truth for resolving category keys into `CategoryDescriptor`s.
//  Holds the user's custom categories (loaded from SwiftData) alongside the
//  built-in ones, and is injected into the environment so any view or service
//  can resolve `CatalogItem.categoryRaw` consistently.
//

import SwiftUI
import SwiftData

@Observable
@MainActor
final class CategoryStore {

    // MARK: - State

    /// User-defined categories, ordered for display.
    private(set) var userCategories: [UserCategory] = []

    private var context: ModelContext?

    // MARK: - Configuration

    /// Wires up the SwiftData context and performs the initial load.
    /// Call once from the root view's `.onAppear`.
    func configure(context: ModelContext) {
        self.context = context
        reload()
    }

    /// Re-fetches custom categories from the store. Call after create/edit/delete.
    func reload() {
        guard let context else { return }
        let descriptor = FetchDescriptor<UserCategory>(
            sortBy: [
                SortDescriptor(\.sortOrder, order: .forward),
                SortDescriptor(\.createdAt, order: .forward),
            ]
        )
        userCategories = (try? context.fetch(descriptor)) ?? []
        syncToAppGroup()
    }

    /// Mirrors custom categories into the App Group so extension processes
    /// (iOS Share Extension, macOS Safari extension) can match and offer them.
    private func syncToAppGroup() {
        let shared = userCategories.map {
            SharedCategory(key: $0.key, name: $0.name, icon: $0.iconName, hint: $0.aiHint)
        }
        AppGroupManager.saveCustomCategories(shared)
    }

    // MARK: - Descriptor collections

    /// Built-in categories first, then custom ones (display order).
    var allDescriptors: [CategoryDescriptor] {
        ItemCategory.allCases.map(\.descriptor) + userCategories.map(\.descriptor)
    }

    var builtInDescriptors: [CategoryDescriptor] {
        ItemCategory.allCases.map(\.descriptor)
    }

    var customDescriptors: [CategoryDescriptor] {
        userCategories.map(\.descriptor)
    }

    // MARK: - Resolution

    /// Resolves a raw category key into a descriptor.
    /// Falls back to a generic "Other" descriptor for unknown keys so that
    /// orphaned items (after a custom category deletion) remain displayable.
    func descriptor(forKey key: String) -> CategoryDescriptor {
        if let builtIn = ItemCategory(rawValue: key) {
            return builtIn.descriptor
        }
        if let custom = userCategories.first(where: { $0.key == key }) {
            return custom.descriptor
        }
        return .unresolved(key: key)
    }

    /// Convenience for resolving the category of a catalog item.
    func descriptor(for item: CatalogItem) -> CategoryDescriptor {
        descriptor(forKey: item.categoryRaw)
    }

    // MARK: - Lookup helpers

    func customCategory(forKey key: String) -> UserCategory? {
        userCategories.first { $0.key == key }
    }

    /// Case-insensitive name lookup across built-in + custom categories.
    /// Used to avoid creating duplicate categories from AI suggestions.
    func descriptor(forName name: String) -> CategoryDescriptor? {
        let target = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !target.isEmpty else { return nil }
        return allDescriptors.first { $0.name.lowercased() == target }
    }

    // MARK: - Mutation

    /// Next sort order to append a new custom category at the end.
    var nextSortOrder: Int {
        (userCategories.map(\.sortOrder).max() ?? -1) + 1
    }
}
