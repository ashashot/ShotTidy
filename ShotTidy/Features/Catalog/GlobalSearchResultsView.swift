//
//  GlobalSearchResultsView.swift
//  ShotTidy
//
//  Global search results across every category, grouped by category.
//  Shown in place of the category grid while a search query is active.
//

import SwiftUI

struct GlobalSearchResultsView: View {
    let items: [CatalogItem]
    let query: String

    @Environment(CategoryStore.self) private var categoryStore

    /// Matching items grouped by category, in the same order as the category grid.
    /// Items whose category no longer resolves are grouped under "Other" at the end.
    private var sections: [(descriptor: CategoryDescriptor, items: [CatalogItem])] {
        var grouped: [String: [CatalogItem]] = [:]
        for item in items where matches(item) {
            grouped[item.categoryRaw, default: []].append(item)
        }
        guard !grouped.isEmpty else { return [] }

        var result: [(CategoryDescriptor, [CatalogItem])] = []
        for descriptor in categoryStore.allDescriptors {
            if let matched = grouped.removeValue(forKey: descriptor.key) {
                result.append((descriptor, matched))
            }
        }
        for key in grouped.keys.sorted() {
            result.append((.unresolved(key: key), grouped[key] ?? []))
        }
        return result
    }

    var body: some View {
        if sections.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            List {
                ForEach(sections, id: \.descriptor) { descriptor, matched in
                    Section {
                        ForEach(matched) { item in
                            NavigationLink {
                                ItemDetailView(item: item)
                            } label: {
                                CatalogItemRow(item: item, schema: descriptor.fieldSchema)
                            }
                        }
                    } header: {
                        Label(descriptor.name, systemImage: descriptor.iconName)
                            .foregroundStyle(descriptor.color)
                    }
                }
            }
        }
    }

    private func matches(_ item: CatalogItem) -> Bool {
        item.title.localizedCaseInsensitiveContains(query) ||
        (item.subtitle?.localizedCaseInsensitiveContains(query) ?? false) ||
        (item.extra1?.localizedCaseInsensitiveContains(query) ?? false) ||
        (item.extra2?.localizedCaseInsensitiveContains(query) ?? false) ||
        (item.notes?.localizedCaseInsensitiveContains(query) ?? false)
    }
}
