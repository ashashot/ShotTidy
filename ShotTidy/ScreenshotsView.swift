//
//  ScreenshotsView.swift
//  ShotTidy
//
//  "Screenshots" tab — backup copy of source images.
//

import SwiftUI
import SwiftData

struct ScreenshotsView: View {
    @Query(sort: [SortDescriptor(\Screenshot.createdAt, order: .reverse)])
    private var screenshots: [Screenshot]

    @Query private var allItems: [CatalogItem]

    @Environment(\.modelContext) private var modelContext
    @Binding var showImport: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if screenshots.isEmpty {
                    ContentUnavailableView(
                        "No Screenshots",
                        systemImage: "photo.stack",
                        description: Text("Import screenshots for analysis.\nThey are saved here as the data source.")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(screenshots) { screenshot in
                                ScreenshotCell(
                                    screenshot: screenshot,
                                    extractedCount: extractedCount(for: screenshot)
                                )
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
            .navigationTitle("Screenshots")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showImport = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                }
                if !screenshots.isEmpty {
                    ToolbarItem(placement: .topBarLeading) {
                        Text("\(screenshots.count) items")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func extractedCount(for screenshot: Screenshot) -> Int {
        allItems.filter { $0.sourceScreenshotId == screenshot.id }.count
    }
}

// MARK: - ScreenshotCell

private struct ScreenshotCell: View {
    let screenshot: Screenshot
    let extractedCount: Int

    var statusColor: Color {
        switch screenshot.analysisStatus {
        case .done:      return .green
        case .analyzing: return .blue
        case .failed:    return .red
        case .pending:   return .gray
        }
    }

    var statusIcon: String {
        switch screenshot.analysisStatus {
        case .done:      return ""
        case .analyzing: return "clock.fill"
        case .failed:    return "exclamationmark.triangle.fill"
        case .pending:   return "clock"
        }
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Thumbnail
            Group {
                if let data = screenshot.thumbnailData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color(.secondarySystemBackground))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.title3)
                                .foregroundStyle(.tertiary)
                        }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fill)
            .clipped()

            // Badge with number of extracted items
            if extractedCount > 0 {
                Text("\(extractedCount)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(statusColor)
                    .clipShape(Capsule())
                    .padding(5)
            } else if screenshot.analysisStatus != .done {
                Image(systemName: statusIcon)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(statusColor)
                    .clipShape(Circle())
                    .padding(5)
            }
        }
    }
}
