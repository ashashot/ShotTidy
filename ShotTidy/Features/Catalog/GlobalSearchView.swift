//
//  GlobalSearchView.swift
//  ShotTidy
//
//  Global search page hosted by the system search tab (Tab(role: .search)).
//  On iOS 26+ the tab bar shows the magnifying glass as a standalone button
//  next to the bar; tapping it expands the search field at the bottom while
//  the remaining tabs collapse — all standard system behavior.
//

import SwiftUI
import SwiftData

struct GlobalSearchView: View {
    @Query private var allItems: [CatalogItem]
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            Group {
                if searchText.isEmpty {
                    ContentUnavailableView(
                        "Search all items",
                        systemImage: "magnifyingglass",
                        description: Text("Find items from every category")
                    )
                } else {
                    GlobalSearchResultsView(items: allItems, query: searchText)
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search all items")
        }
    }
}
