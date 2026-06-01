//
//  ScreenshotDetailView.swift
//  ShotTidy
//
//  Detailed view for a source screenshot showing all extracted catalog items.
//

import SwiftUI
import SwiftData

struct ScreenshotDetailView: View {
    let screenshot: Screenshot

    @Query private var linkedItems: [CatalogItem]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(CategoryStore.self) private var categoryStore

    @State private var showDeleteAlert = false

    init(screenshot: Screenshot) {
        self.screenshot = screenshot
        let sid = screenshot.id
        _linkedItems = Query(
            filter: #Predicate<CatalogItem> { item in
                item.sourceScreenshotId == sid
            },
            sort: [SortDescriptor(\CatalogItem.createdAt)]
        )
    }

    // Items grouped by category descriptor in display order
    private var groupedByCategory: [(CategoryDescriptor, [CatalogItem])] {
        let grouped = Dictionary(grouping: linkedItems) { $0.categoryRaw }
        return categoryStore.allDescriptors.compactMap { descriptor in
            guard let items = grouped[descriptor.key], !items.isEmpty else { return nil }
            return (descriptor, items)
        }
    }

    var body: some View {
        List {
            // Screenshot preview
            if let data = screenshot.thumbnailData, let img = UIImage(data: data) {
                Section {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12))
                .listRowBackground(Color.clear)
            }

            // Catalog items grouped by category
            if linkedItems.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Items",
                        systemImage: "tray",
                        description: Text("No catalog items were saved from this screenshot.")
                    )
                }
            } else {
                ForEach(groupedByCategory, id: \.0) { descriptor, items in
                    Section {
                        ForEach(items) { item in
                            NavigationLink(destination: ItemDetailView(item: item)) {
                                CatalogItemRow(item: item, schema: descriptor.fieldSchema)
                            }
                        }
                    } header: {
                        Label(descriptor.name, systemImage: descriptor.iconName)
                            .foregroundStyle(descriptor.color)
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Screenshot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("\(linkedItems.count) \(linkedItems.count == 1 ? "item" : "items")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
            }
        }
        .alert("Delete Screenshot?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(screenshot)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The screenshot backup will be removed. Catalog items extracted from it will not be affected.")
        }
    }
}
