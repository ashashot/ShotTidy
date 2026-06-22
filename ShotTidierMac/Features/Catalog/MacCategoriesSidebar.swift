//
//  MacCategoriesSidebar.swift
//  ShotTidierMac
//

import SwiftUI
import SwiftData

// MARK: - SidebarItem

enum SidebarItem: Hashable {
    case category(String)
    case screenshots
}

// MARK: - MacCategoriesSidebar

struct MacCategoriesSidebar: View {

    @Binding var selection: SidebarItem?
    @Binding var showImport: Bool

    @Query private var allItems: [CatalogItem]
    @Environment(CategoryStore.self) private var categoryStore

    @State private var showCategoryManager = false

    /// Item counts grouped by category key, computed in a single pass instead of
    /// re-filtering the whole collection once per category row.
    private var countsByCategory: [String: Int] {
        allItems.reduce(into: [:]) { counts, item in
            counts[item.categoryRaw, default: 0] += 1
        }
    }

    var body: some View {
        let counts = countsByCategory
        List(selection: $selection) {
            Section("Catalog") {
                ForEach(categoryStore.allDescriptors) { descriptor in
                    Label {
                        HStack {
                            Text(descriptor.name)
                            Spacer()
                            let c = counts[descriptor.key] ?? 0
                            if c > 0 {
                                Text("\(c)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    } icon: {
                        Image(systemName: descriptor.iconName)
                            .foregroundStyle(descriptor.color)
                    }
                    .tag(SidebarItem.category(descriptor.key))
                }
            }

            Section("Library") {
                Label("Screenshots", systemImage: "photo.stack.fill")
                    .tag(SidebarItem.screenshots)
            }
        }
        .navigationTitle("ShotTidier")
        .listStyle(.sidebar)
        .toolbar {
            ToolbarItem {
                Button {
                    showCategoryManager = true
                } label: {
                    Image(systemName: "folder.badge.gearshape")
                }
                .help("Manage Categories")
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showImport = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Import Screenshots")
            }
        }
        .sheet(isPresented: $showCategoryManager) {
            MacCategoryManagerView()
        }
    }
}
