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

    // Items grouped by category in display order
    private var groupedByCategory: [(ItemCategory, [CatalogItem])] {
        let grouped = Dictionary(grouping: linkedItems) { $0.category }
        return ItemCategory.allCases.compactMap { category in
            guard let items = grouped[category], !items.isEmpty else { return nil }
            return (category, items)
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
                ForEach(groupedByCategory, id: \.0) { category, items in
                    Section {
                        ForEach(items) { item in
                            NavigationLink(destination: ItemDetailView(item: item)) {
                                CatalogItemRow(item: item, schema: item.category.fieldSchema)
                            }
                        }
                    } header: {
                        Label(category.localizedName, systemImage: category.icon)
                            .foregroundStyle(category.color)
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Screenshot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text("\(linkedItems.count) \(linkedItems.count == 1 ? "item" : "items")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
