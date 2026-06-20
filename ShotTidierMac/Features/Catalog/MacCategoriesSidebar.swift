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

    private func count(for descriptor: CategoryDescriptor) -> Int {
        allItems.filter { $0.categoryRaw == descriptor.key }.count
    }

    var body: some View {
        List(selection: $selection) {
            Section("Catalog") {
                ForEach(categoryStore.allDescriptors) { descriptor in
                    Label {
                        HStack {
                            Text(descriptor.name)
                            Spacer()
                            let c = count(for: descriptor)
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
