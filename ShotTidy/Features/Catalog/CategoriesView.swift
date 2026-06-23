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
    /// Cached hide-completed flags; refreshed on appear so count badges stay in sync.
    @State private var hideCompleted: [String: Bool] = [:]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    /// Built-in categories first, then custom ones — each with its visible item count.
    private var categoryCounts: [(CategoryDescriptor, Int)] {
        categoryStore.allDescriptors.map { descriptor in
            let shouldHide = hideCompleted[descriptor.key] ?? false
            let count = allItems.filter {
                $0.categoryRaw == descriptor.key && (!shouldHide || !$0.isCompleted)
            }.count
            return (descriptor, count)
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
            .navigationTitle("Catalog")
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

    // MARK: - Helpers

    private func refreshHideCompleted() {
        let keys = categoryStore.allDescriptors.map { $0.key }
        hideCompleted = Dictionary(
            uniqueKeysWithValues: keys.map { ($0, AppGroupManager.hideCompleted(forCategory: $0)) }
        )
    }
}
