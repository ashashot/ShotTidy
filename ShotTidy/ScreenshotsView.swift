//
//  ScreenshotsView.swift
//  ShotTidy
//
//  "Screenshots" tab — backup copies of source images that have confirmed catalog items.
//

import SwiftUI
import SwiftData

struct ScreenshotsView: View {
    /// Only show screenshots from which the user has saved at least one catalog item.
    @Query(
        filter: #Predicate<Screenshot> { $0.extractedItemsCount > 0 },
        sort: [SortDescriptor(\Screenshot.createdAt, order: .reverse)]
    )
    private var screenshots: [Screenshot]

    /// Used to compute the actual number of confirmed items per screenshot.
    @Query private var allItems: [CatalogItem]

    @Environment(\.modelContext) private var modelContext
    @Binding var showImport: Bool

    /// navigationDestination(item:) instead of NavigationLink inside LazyVGrid —
    /// prevents layout recalculations that cause scroll jitter.
    @State private var selectedScreenshot: Screenshot? = nil

    private static let columnCount: Int = 3
    private static let cellSpacing: CGFloat = 2

    var body: some View {
        NavigationStack {
            screenshotsContent
                .navigationTitle(screenshots.isEmpty ? "Screenshots" : "\(screenshots.count) \(screenshots.count == 1 ? "Screenshot" : "Screenshots")")
                .navigationDestination(item: $selectedScreenshot) { screenshot in
                    ScreenshotDetailView(screenshot: screenshot)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button { showImport = true } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                    }
                }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var screenshotsContent: some View {
        if screenshots.isEmpty {
            ContentUnavailableView(
                "No Screenshots",
                systemImage: "photo.stack",
                description: Text("Screenshots appear here once you save\ncatalog items extracted from them.")
            )
        } else {
            // GeometryReader provides the available width so every cell gets
            // an explicit, fixed frame — the only reliable way to prevent
            // LazyVGrid from recalculating cell heights during scroll.
            GeometryReader { proxy in
                let n = CGFloat(Self.columnCount)
                let s = Self.cellSpacing
                let cellWidth  = floor((proxy.size.width - s * (n - 1)) / n)
                let cellHeight = floor(cellWidth * 16 / 9)
                let gridColumns = Array(
                    repeating: GridItem(.fixed(cellWidth), spacing: s),
                    count: Self.columnCount
                )

                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: s) {
                        ForEach(screenshots) { screenshot in
                            ScreenshotCell(
                                screenshot: screenshot,
                                extractedCount: confirmedCount(for: screenshot),
                                cellWidth: cellWidth,
                                cellHeight: cellHeight
                            )
                            .onTapGesture { selectedScreenshot = screenshot }
                            .contextMenu {
                                Button("Delete", role: .destructive) {
                                    modelContext.delete(screenshot)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Returns the number of CatalogItems actually saved from this screenshot.
    private func confirmedCount(for screenshot: Screenshot) -> Int {
        allItems.filter { $0.sourceScreenshotId == screenshot.id }.count
    }
}

// MARK: - ScreenshotCell

private struct ScreenshotCell: View {
    let screenshot: Screenshot
    let extractedCount: Int
    let cellWidth: CGFloat
    let cellHeight: CGFloat

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Thumbnail — explicit fixed frame prevents any size ambiguity
            Group {
                if let data = screenshot.thumbnailData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(uiColor: .secondarySystemBackground)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.title3)
                                .foregroundStyle(.tertiary)
                        }
                }
            }
            .frame(width: cellWidth, height: cellHeight)
            .clipped()

            // Badge with actual confirmed-item count
            if extractedCount > 0 {
                Text("\(extractedCount)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.blue)
                    .clipShape(Capsule())
                    .padding(5)
            }
        }
        // Single explicit frame for the entire cell — LazyVGrid never needs to remeasure
        .frame(width: cellWidth, height: cellHeight)
    }
}
