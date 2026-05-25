//
//  CategoriesView.swift
//  ShotTidy
//
//  Main screen — catalog category grid.
//

import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Query private var allItems: [CatalogItem]
    @Binding var showImport: Bool

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    // Categories with item counts
    private var categoryCounts: [(ItemCategory, Int)] {
        ItemCategory.allCases.map { category in
            let count = allItems.filter { $0.categoryRaw == category.rawValue }.count
            return (category, count)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(categoryCounts, id: \.0) { category, count in
                        NavigationLink {
                            CategoryListView(category: category)
                        } label: {
                            CategoryCardView(category: category, count: count)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Catalog")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showImport = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }
}
