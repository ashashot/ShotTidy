//
//  ContentView.swift
//  ShotTidyMac
//
//  Root NavigationSplitView: sidebar (categories) | item list | item detail.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @State private var sidebarSelection: SidebarItem? = .category("shopping")
    @State private var selectedItem: CatalogItem?
    @State private var showImport = false

    @Environment(\.modelContext) private var modelContext
    @Environment(CategoryStore.self) private var categoryStore

    @Query private var userCategories: [UserCategory]

    var body: some View {
        NavigationSplitView {
            MacCategoriesSidebar(selection: $sidebarSelection, showImport: $showImport)
        } content: {
            contentView
        } detail: {
            detailView
        }
        .sheet(isPresented: $showImport) {
            NavigationStack {
                MacImportView()
                    .navigationTitle("Import Screenshots")
            }
        }
        .onAppear {
            categoryStore.configure(context: modelContext)
        }
        .onChange(of: userCategories.count) { _, _ in
            categoryStore.reload()
        }
    }

    // MARK: - Content column

    @ViewBuilder
    private var contentView: some View {
        switch sidebarSelection {
        case .category(let key):
            let descriptor = categoryStore.descriptor(forKey: key)
            MacCategoryItemsView(descriptor: descriptor, selectedItem: $selectedItem)
        case .screenshots:
            MacScreenshotsView()
        case nil:
            Text("Select a category")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Detail column

    @ViewBuilder
    private var detailView: some View {
        if let item = selectedItem {
            MacItemDetailView(item: item)
        } else {
            VStack(spacing: 16) {
                Image(systemName: "sidebar.right")
                    .font(.system(size: 40))
                    .foregroundStyle(.quaternary)
                Text("Select an item to view details")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
