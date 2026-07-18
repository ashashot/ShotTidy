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
    private static let cellSpacing: CGFloat = 10
    private static let gridPadding: CGFloat = 16

    var body: some View {
        NavigationStack {
            screenshotsContent
                .background(Color(.systemGroupedBackground))
                .navigationTitle(screenshots.isEmpty ? String(localized: "Screenshots", bundle: AppLocale.bundle) : String(localized: "\(screenshots.count) Screenshot(s)", bundle: AppLocale.bundle))
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
                .alert(String(localized: "Delete \(selectedIDs.count) Screenshot(s)?", bundle: AppLocale.bundle),
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
                            ? String(localized: "Select Screenshots to Delete", bundle: AppLocale.bundle)
                            : String(localized: "Delete \(selectedIDs.count) Screenshot(s)", bundle: AppLocale.bundle)
                    )
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(selectedIDs.isEmpty ? Color(.secondaryLabel) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    selectedIDs.isEmpty
                        ? AnyShapeStyle(Color(.tertiarySystemFill))
                        : AnyShapeStyle(Color.red),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
            }
            .disabled(selectedIDs.isEmpty)
            .animation(.easeInOut(duration: 0.15), value: selectedIDs.isEmpty)
            .padding(.horizontal, Self.gridPadding)
            .padding(.vertical, 10)
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
            ContentUnavailableView {
                Label("No Screenshots", systemImage: "photo.stack")
            } description: {
                Text("Screenshots appear here once you save\ncatalog items extracted from them.")
            } actions: {
                Button {
                    showImport = true
                } label: {
                    Text("Import Screenshots")
                        .font(.body.weight(.medium))
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
            }
        } else {
            // GeometryReader provides the available width so every cell gets
            // an explicit, fixed frame — the only reliable way to prevent
            // LazyVGrid from recalculating cell heights during scroll.
            GeometryReader { proxy in
                let n = CGFloat(Self.columnCount)
                let s = Self.cellSpacing
                let cellWidth  = floor((proxy.size.width - Self.gridPadding * 2 - s * (n - 1)) / n)
                let cellHeight = floor(cellWidth * 16 / 9)
                let gridColumns = Array(
                    repeating: GridItem(.fixed(cellWidth), spacing: s),
                    count: Self.columnCount
                )

                let confirmedCounts = self.confirmedCounts

                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: s) {
                        ForEach(screenshots) { screenshot in
                            Button {
                                if isEditing {
                                    toggleSelection(for: screenshot)
                                } else {
                                    selectedScreenshot = screenshot
                                }
                            } label: {
                                ScreenshotCell(
                                    screenshot: screenshot,
                                    extractedCount: confirmedCounts[screenshot.id] ?? 0,
                                    cellWidth: cellWidth,
                                    cellHeight: cellHeight,
                                    isEditing: isEditing,
                                    isSelected: selectedIDs.contains(screenshot.id)
                                )
                            }
                            .buttonStyle(ScreenshotCellButtonStyle())
                            .contextMenu {
                                if !isEditing {
                                    Button("Delete", role: .destructive) {
                                        modelContext.delete(screenshot)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Self.gridPadding)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    // Extra bottom padding so bottom bar doesn't overlap last row
                    if isEditing { Color.clear.frame(height: 60) }
                }
            }
        }
    }

    // MARK: - Helpers

    /// Confirmed-item counts per screenshot, aggregated in a single pass
    /// instead of filtering the full item array once per grid cell.
    private var confirmedCounts: [UUID: Int] {
        var counts: [UUID: Int] = [:]
        for item in allItems {
            if let sid = item.sourceScreenshotId {
                counts[sid, default: 0] += 1
            }
        }
        return counts
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

    private static let cornerRadius: CGFloat = 14

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
                    Color.black.opacity(0.3)
                }
            }

            // Bottom scrim keeps the count legible over any thumbnail
            if extractedCount > 0 && !isEditing {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(width: cellWidth, height: 52)
                .allowsHitTesting(false)

                HStack(spacing: 4) {
                    Image(systemName: "square.stack.fill")
                        .font(.system(size: 9, weight: .semibold))
                    Text("\(extractedCount)")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }

            // Selection indicator — Photos-style, bottom-trailing
            if isEditing {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(.blue)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    } else {
                        Circle()
                            .fill(.black.opacity(0.2))
                        Circle()
                            .strokeBorder(.white, lineWidth: 1.5)
                    }
                }
                .frame(width: 22, height: 22)
                .shadow(color: .black.opacity(0.25), radius: 2)
                .padding(7)
            }
        }
        // Single explicit frame for the entire cell — LazyVGrid never needs to remeasure
        .frame(width: cellWidth, height: cellHeight)
        .clipShape(RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                .strokeBorder(
                    isSelected ? AnyShapeStyle(Color.blue) : AnyShapeStyle(.primary.opacity(0.08)),
                    lineWidth: isSelected ? 2.5 : 1
                )
        }
    }
}

// MARK: - ScreenshotCellButtonStyle

/// Subtle scale-down press feedback; keeps the fixed cell frame intact.
private struct ScreenshotCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
