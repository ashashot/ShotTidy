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

    // MARK: - Edit / Delete state
    @State private var isEditing = false
    @State private var selectedIDs: Set<UUID> = []
    @State private var showBatchDeleteAlert = false

    private static let columnCount: Int = 3
    private static let cellSpacing: CGFloat = 2

    var body: some View {
        NavigationStack {
            screenshotsContent
                .navigationTitle(screenshots.isEmpty ? "Screenshots" : "\(screenshots.count) \(screenshots.count == 1 ? "Screenshot" : "Screenshots")")
                .navigationDestination(item: $selectedScreenshot) { screenshot in
                    ScreenshotDetailView(screenshot: screenshot)
                }
                .toolbar { toolbarContent }
                .animation(.default, value: isEditing)
                .safeAreaInset(edge: .bottom) {
                    if isEditing {
                        deleteBarView
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .alert("Delete \(selectedIDs.count) \(selectedIDs.count == 1 ? "Screenshot" : "Screenshots")?",
                       isPresented: $showBatchDeleteAlert) {
                    Button("Delete", role: .destructive) { deleteSelected() }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("The associated catalog items will not be deleted.")
                }
        }
    }

    // MARK: - Delete bar (safeAreaInset)

    private var deleteBarView: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                showBatchDeleteAlert = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                    Text(
                        selectedIDs.isEmpty
                            ? "Select Screenshots to Delete"
                            : "Delete \(selectedIDs.count) \(selectedIDs.count == 1 ? "Screenshot" : "Screenshots")"
                    )
                }
                .font(.body.weight(.medium))
                .foregroundStyle(selectedIDs.isEmpty ? Color(.secondaryLabel) : Color.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .disabled(selectedIDs.isEmpty)
            .background(.bar)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        // "+" button — hidden in edit mode
        if !isEditing {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showImport = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }
            }
        }

        // Edit / Done
        if !screenshots.isEmpty {
            ToolbarItem(placement: .topBarLeading) {
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation {
                        isEditing.toggle()
                        if !isEditing { selectedIDs.removeAll() }
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
                                cellHeight: cellHeight,
                                isEditing: isEditing,
                                isSelected: selectedIDs.contains(screenshot.id)
                            )
                            .onTapGesture {
                                if isEditing {
                                    toggleSelection(for: screenshot)
                                } else {
                                    selectedScreenshot = screenshot
                                }
                            }
                            .contextMenu {
                                if !isEditing {
                                    Button("Delete", role: .destructive) {
                                        modelContext.delete(screenshot)
                                    }
                                }
                            }
                        }
                    }
                    // Extra bottom padding so bottom bar doesn't overlap last row
                    if isEditing { Color.clear.frame(height: 60) }
                }
            }
        }
    }

    // MARK: - Helpers

    private func confirmedCount(for screenshot: Screenshot) -> Int {
        allItems.filter { $0.sourceScreenshotId == screenshot.id }.count
    }

    private func toggleSelection(for screenshot: Screenshot) {
        if selectedIDs.contains(screenshot.id) {
            selectedIDs.remove(screenshot.id)
        } else {
            selectedIDs.insert(screenshot.id)
        }
    }

    private func deleteSelected() {
        let toDelete = screenshots.filter { selectedIDs.contains($0.id) }
        for screenshot in toDelete {
            modelContext.delete(screenshot)
        }
        selectedIDs.removeAll()
        withAnimation { isEditing = false }
    }
}

// MARK: - ScreenshotCell

private struct ScreenshotCell: View {
    let screenshot: Screenshot
    let extractedCount: Int
    let cellWidth: CGFloat
    let cellHeight: CGFloat
    var isEditing: Bool = false
    var isSelected: Bool = false

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
            // Dim when selected
            .overlay {
                if isSelected {
                    Color.black.opacity(0.35)
                }
            }

            // Badge with actual confirmed-item count (hidden during edit mode)
            if extractedCount > 0 && !isEditing {
                Text("\(extractedCount)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(.blue)
                    .clipShape(Capsule())
                    .padding(5)
            }

            // Selection indicator (top-leading)
            if isEditing {
                VStack {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(isSelected ? Color.blue : Color.black.opacity(0.35))
                                .frame(width: 24, height: 24)
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.white)
                            } else {
                                Circle()
                                    .strokeBorder(.white, lineWidth: 2)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .padding(6)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        // Single explicit frame for the entire cell — LazyVGrid never needs to remeasure
        .frame(width: cellWidth, height: cellHeight)
    }
}
