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
    @Binding var navigationPath: NavigationPath

    @Environment(CategoryStore.self) private var categoryStore

    @State private var showCategoryManager = false
    @State private var showManualAdd = false
    @State private var searchText = ""
    /// Cached hide-completed flags; refreshed on appear so count badges stay in sync.
    @State private var hideCompleted: [String: Bool] = [:]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    /// Built-in categories first, then custom ones — each with its visible item count.
    /// Counts are aggregated in a single pass over the items instead of
    /// filtering the full array once per category.
    private var categoryCounts: [(CategoryDescriptor, Int)] {
        var totalCounts: [String: Int] = [:]
        var activeCounts: [String: Int] = [:]
        for item in allItems {
            totalCounts[item.categoryRaw, default: 0] += 1
            if !item.isCompleted {
                activeCounts[item.categoryRaw, default: 0] += 1
            }
        }
        return categoryStore.allDescriptors.map { descriptor in
            let shouldHide = hideCompleted[descriptor.key] ?? false
            let counts = shouldHide ? activeCounts : totalCounts
            return (descriptor, counts[descriptor.key] ?? 0)
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if searchText.isEmpty {
                    categoryGrid
                } else {
                    GlobalSearchResultsView(items: allItems, query: searchText)
                }
            }
            .navigationTitle("Catalog")
            .legacyGlobalSearch(text: $searchText)
            .onAppear { refreshHideCompleted() }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                refreshHideCompleted()
            }
            .navigationDestination(for: CategoryDescriptor.self) { category in
                CategoryListView(descriptor: category)
            }
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
                    Menu {
                        Button {
                            showManualAdd = true
                        } label: {
                            Label("Add Manually", systemImage: "pencil")
                        }
                        Button {
                            showImport = true
                        } label: {
                            Label("Import Screenshots", systemImage: "photo.badge.plus")
                        }
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
            .sheet(isPresented: $showManualAdd) {
                ManualAddView()
            }
        }
    }

    // MARK: - Category Grid

    private var categoryGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(categoryCounts, id: \.0) { category, count in
                    NavigationLink(value: category) {
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
    }

    // MARK: - Helpers

    private func refreshHideCompleted() {
        let keys = categoryStore.allDescriptors.map { $0.key }
        hideCompleted = Dictionary(
            uniqueKeysWithValues: keys.map { ($0, AppGroupManager.hideCompleted(forCategory: $0)) }
        )
    }
}

// MARK: - Legacy global search

private extension View {
    /// On iOS 26+ global search lives in the system search tab at the bottom
    /// (see MainTabView), so no field is attached here. Earlier systems fall
    /// back to a search field in the Catalog navigation bar.
    @ViewBuilder
    func legacyGlobalSearch(text: Binding<String>) -> some View {
        if #available(iOS 26.0, *) {
            self
        } else {
            self.searchable(text: text, prompt: "Search all items")
        }
    }
}
