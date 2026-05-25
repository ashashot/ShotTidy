//
//  CategoryListView.swift
//  ShotTidy
//
//  List of items within a single category.
//

import SwiftUI
import SwiftData

struct CategoryListView: View {
    let category: ItemCategory

    @Query var items: [CatalogItem]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var showAddManually = false
    @State private var sortByDate = true

    init(category: ItemCategory) {
        self.category = category
        let raw = category.rawValue
        _items = Query(
            filter: #Predicate<CatalogItem> { item in
                item.categoryRaw == raw
            },
            sort: [SortDescriptor(\CatalogItem.createdAt, order: .reverse)]
        )
    }

    private var filtered: [CatalogItem] {
        guard !searchText.isEmpty else { return items }
        let q = searchText.lowercased()
        return items.filter { item in
            item.title.lowercased().contains(q) ||
            (item.subtitle?.lowercased().contains(q) ?? false) ||
            (item.extra1?.lowercased().contains(q) ?? false) ||
            (item.notes?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView(
                    category.localizedName,
                    systemImage: category.icon,
                    description: Text("No items.\nAdd via screenshot import or the «+» button")
                )
            } else {
                List {
                    ForEach(filtered) { item in
                        NavigationLink {
                            ItemDetailView(item: item)
                        } label: {
                            CatalogItemRow(item: item, schema: category.fieldSchema)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(filtered[index])
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search in \(category.localizedName)")
            }
        }
        .navigationTitle(category.localizedName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddManually = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddManually) {
            ItemEditView(category: category, item: nil)
        }
    }
}
