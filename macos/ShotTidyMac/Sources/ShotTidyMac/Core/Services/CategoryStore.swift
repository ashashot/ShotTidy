//
//  CategoryStore.swift
//  ShotTidyMac
//

import SwiftUI
import SwiftData

@Observable
@MainActor
final class CategoryStore {

    private(set) var userCategories: [UserCategory] = []
    private var context: ModelContext?

    func configure(context: ModelContext) {
        self.context = context
        reload()
    }

    func reload() {
        guard let context else { return }
        let descriptor = FetchDescriptor<UserCategory>(
            sortBy: [
                SortDescriptor(\.sortOrder, order: .forward),
                SortDescriptor(\.createdAt, order: .forward),
            ]
        )
        userCategories = (try? context.fetch(descriptor)) ?? []
    }

    var allDescriptors: [CategoryDescriptor] {
        ItemCategory.allCases.map(\.descriptor) + userCategories.map(\.descriptor)
    }

    var builtInDescriptors: [CategoryDescriptor] {
        ItemCategory.allCases.map(\.descriptor)
    }

    var customDescriptors: [CategoryDescriptor] {
        userCategories.map(\.descriptor)
    }

    func descriptor(forKey key: String) -> CategoryDescriptor {
        if let builtIn = ItemCategory(rawValue: key) {
            return builtIn.descriptor
        }
        if let custom = userCategories.first(where: { $0.key == key }) {
            return custom.descriptor
        }
        return .unresolved(key: key)
    }

    func descriptor(for item: CatalogItem) -> CategoryDescriptor {
        descriptor(forKey: item.categoryRaw)
    }

    func descriptor(forName name: String) -> CategoryDescriptor? {
        let target = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !target.isEmpty else { return nil }
        return allDescriptors.first { $0.name.lowercased() == target }
    }

    var nextSortOrder: Int {
        (userCategories.map(\.sortOrder).max() ?? -1) + 1
    }
}
