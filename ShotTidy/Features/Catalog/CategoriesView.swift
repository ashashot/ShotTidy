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

    @Environment(CategoryStore.self) private var categoryStore

    @State private var showCategoryManager = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    /// Built-in categories first, then custom ones — each with its item count.
    private var categoryCounts: [(CategoryDescriptor, Int)] {
        categoryStore.allDescriptors.map { descriptor in
            let count = allItems.filter { $0.categoryRaw == descriptor.key }.count
            return (descriptor, count)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(categoryCounts, id: \.0) { category, count in
                        NavigationLink {
                            CategoryListView(descriptor: category)
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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showCategoryManager = true
                    } label: {
                        Image(systemName: "folder.badge.gearshape")
                            .font(.body)
                            .foregroundStyle(.blue)
                    }
                    .accessibilityLabel("Manage Categories")
                }
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
            .sheet(isPresented: $showCategoryManager) {
                CategoryManagerView()
            }
        }
    }
}
