//
//  MacCategoryItemsView.swift
//  ShotTidierMac
//

import SwiftUI
import SwiftData

struct MacCategoryItemsView: View {

    let descriptor: CategoryDescriptor
    @Binding var selectedItem: CatalogItem?

    @Query var items: [CatalogItem]
    @Environment(\.modelContext) private var modelContext

    @State private var searchText = ""
    @State private var showAddItem = false
    @State private var hideCompleted = false

    init(descriptor: CategoryDescriptor, selectedItem: Binding<CatalogItem?>) {
        self.descriptor = descriptor
        self._selectedItem = selectedItem
        let raw = descriptor.key
        _items = Query(
            filter: #Predicate<CatalogItem> { item in item.categoryRaw == raw },
            sort: [SortDescriptor(\CatalogItem.createdAt, order: .reverse)]
        )
    }

    private var supportsHideCompleted: Bool {
        descriptor.key == "shopping" || descriptor.key == "tasks"
    }

    private var filtered: [CatalogItem] {
        var result = items
        if supportsHideCompleted && hideCompleted {
            result = result.filter { !$0.isCompleted }
        }
        guard !searchText.isEmpty else { return result }
        let q = searchText.lowercased()
        return result.filter { item in
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
                    descriptor.name,
                    systemImage: descriptor.iconName,
                    description: Text("No items yet.\nClick «+» to add or use Import to analyze screenshots.")
                )
            } else if filtered.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else if filtered.isEmpty && hideCompleted {
                ContentUnavailableView(
                    descriptor.key == "shopping" ? "All Purchased!" : "All Done!",
                    systemImage: "checkmark.circle.fill",
                    description: Text("All items are hidden. Toggle the filter to show them.")
                )
            } else {
                List(filtered, selection: $selectedItem) { item in
                    MacCatalogItemRow(item: item, schema: descriptor.fieldSchema)
                        .tag(item)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                if selectedItem?.id == item.id { selectedItem = nil }
                                modelContext.delete(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle(descriptor.name)
        .searchable(text: $searchText, prompt: "Search in \(descriptor.name)")
        .toolbar {
            if supportsHideCompleted {
                ToolbarItem {
                    Button {
                        hideCompleted.toggle()
                    } label: {
                        Image(
                            systemName: hideCompleted
                                ? "line.3.horizontal.decrease.circle.fill"
                                : "line.3.horizontal.decrease.circle"
                        )
                        .foregroundStyle(hideCompleted ? Color.accentColor : Color.primary)
                    }
                    .help(hideCompleted ? "Show Completed" : "Hide Completed")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add Item")
            }
        }
        .sheet(isPresented: $showAddItem) {
            MacItemEditView(descriptor: descriptor, item: nil)
        }
    }
}

// MARK: - MacCatalogItemRow

struct MacCatalogItemRow: View {
    let item: CatalogItem
    let schema: ItemCategory.FieldSchema

    var body: some View {
        HStack(spacing: 10) {
            if item.isCompletableCategory {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? Color.green : Color.secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.body)
                    .lineLimit(1)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)

                if let sub = item.subtitle, !sub.isEmpty {
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            if let link = item.link, !link.isEmpty {
                Image(systemName: schema.isLinkEmail ? "envelope" : "link")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
