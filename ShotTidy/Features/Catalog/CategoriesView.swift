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
    /// True once the content is scrolled; drives the top blur visibility.
    @State private var isScrolled = false
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
        GeometryReader { rootGeo in
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
                .toolbarBackground(.hidden, for: .navigationBar)
                .scrollEdgeEffectHidden(for: .top)
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    geometry.contentOffset.y + geometry.contentInsets.top > 1
                } action: { _, scrolled in
                    isScrolled = scrolled
                }
                .overlay {
                    topBarBlur(statusBarHeight: rootGeo.safeAreaInsets.top)
                        .opacity(isScrolled ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: isScrolled)
                }
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
    }

    /// Fixed-height top blur pinned to the physical top of the screen.
    /// The solid part covers the status bar and the compact navigation bar,
    /// then dissolves into the content with no hard edge. Sized from the root
    /// safe area (status bar only) so it never swallows the large title at rest.
    private func topBarBlur(statusBarHeight: CGFloat) -> some View {
        let solidHeight = statusBarHeight + 44 // compact navigation bar height
        let fadeHeight: CGFloat = 24
        let totalHeight = solidHeight + fadeHeight
        return VStack(spacing: 0) {
            Rectangle()
                .fill(.ultraThinMaterial)
//                .mask {
//                    LinearGradient(
//                        stops: [
//                            .init(color: .black, location: 0),
//                            .init(color: .black, location: solidHeight / totalHeight),
//                            .init(color: .clear, location: 1)
//                        ],
//                        startPoint: .top,
//                        endPoint: .bottom
//                    )
//                }
                .frame(height: totalHeight)
            Spacer(minLength: 0)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Helpers

    private func refreshHideCompleted() {
        let keys = categoryStore.allDescriptors.map { $0.key }
        hideCompleted = Dictionary(
            uniqueKeysWithValues: keys.map { ($0, AppGroupManager.hideCompleted(forCategory: $0)) }
        )
    }
}

