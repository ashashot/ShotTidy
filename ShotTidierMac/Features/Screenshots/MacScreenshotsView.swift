//
//  MacScreenshotsView.swift
//  ShotTidierMac
//

import SwiftUI
import SwiftData

struct MacScreenshotsView: View {

    @Query(
        filter: #Predicate<Screenshot> { $0.extractedItemsCount > 0 },
        sort: [SortDescriptor(\Screenshot.createdAt, order: .reverse)]
    )
    private var screenshots: [Screenshot]

    @Environment(\.modelContext) private var modelContext
    @State private var selectedScreenshot: Screenshot?

    let columns = [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 12)]

    var body: some View {
        Group {
            if screenshots.isEmpty {
                ContentUnavailableView(
                    "No Screenshots",
                    systemImage: "photo.stack",
                    description: Text("Import screenshots with AI analysis to build your catalog.")
                )
            } else {
                HSplitView {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(screenshots) { screenshot in
                                ScreenshotCell(
                                    screenshot: screenshot,
                                    isSelected: selectedScreenshot?.id == screenshot.id
                                )
                                .onTapGesture {
                                    selectedScreenshot = screenshot
                                }
                            }
                        }
                        .padding(16)
                    }
                    .frame(minWidth: 300)

                    if let screenshot = selectedScreenshot {
                        MacScreenshotDetailView(screenshot: screenshot)
                            .frame(minWidth: 260)
                    } else {
                        Text("Select a screenshot")
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 260, maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
        .navigationTitle("Screenshots")
    }
}

// MARK: - ScreenshotCell

private struct ScreenshotCell: View {
    let screenshot: Screenshot
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            thumbnailView
                .frame(width: 130, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )

            VStack(spacing: 2) {
                Text("\(screenshot.extractedItemsCount) item\(screenshot.extractedItemsCount == 1 ? "" : "s")")
                    .font(.caption.weight(.medium))
                Text(screenshot.createdAt, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let data = screenshot.thumbnailData, let img = NSImage(data: data) {
            Image(nsImage: img)
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.15))
                .overlay(
                    Image(systemName: "photo")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                )
        }
    }
}

// MARK: - MacScreenshotDetailView

struct MacScreenshotDetailView: View {
    let screenshot: Screenshot

    @Query private var linkedItems: [CatalogItem]
    @Environment(CategoryStore.self) private var categoryStore

    init(screenshot: Screenshot) {
        self.screenshot = screenshot
        let sid = screenshot.id
        _linkedItems = Query(
            filter: #Predicate<CatalogItem> { $0.sourceScreenshotId == sid },
            sort: [SortDescriptor(\CatalogItem.createdAt)]
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let data = screenshot.thumbnailData, let img = NSImage(data: data) {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let name = screenshot.originalFileName {
                        Text(name)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    Text(screenshot.createdAt.formatted(date: .complete, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if !linkedItems.isEmpty {
                    Divider()
                    Text("Extracted Items")
                        .font(.headline)
                    ForEach(linkedItems) { item in
                        let descriptor = categoryStore.descriptor(for: item)
                        HStack(spacing: 8) {
                            Image(systemName: descriptor.iconName)
                                .foregroundStyle(descriptor.color)
                                .frame(width: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.title)
                                    .font(.body)
                                    .lineLimit(1)
                                Text(descriptor.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(16)
        }
    }
}
