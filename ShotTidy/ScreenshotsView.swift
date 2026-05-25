//
//  ScreenshotsView.swift
//  ShotTidy
//
//  Раздел «Скриншоты» — резервная копия исходных изображений.
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
                        "Нет скриншотов",
                        systemImage: "photo.stack",
                        description: Text("Импортируйте скриншоты для анализа.\nОни сохраняются здесь как источник данных.")
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
                                    Button("Удалить", role: .destructive) {
                                        modelContext.delete(screenshot)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Скриншоты")
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
                        Text("\(screenshots.count) шт.")
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
            // Миниатюра
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

            // Бейдж с числом извлечённых элементов
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
