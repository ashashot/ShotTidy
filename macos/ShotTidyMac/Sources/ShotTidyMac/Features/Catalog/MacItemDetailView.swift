//
//  MacItemDetailView.swift
//  ShotTidyMac
//

import SwiftUI
import SwiftData

struct MacItemDetailView: View {

    @Bindable var item: CatalogItem
    @Environment(\.modelContext) private var modelContext
    @Environment(CategoryStore.self) private var categoryStore

    @State private var showEdit = false
    @State private var showDeleteAlert = false

    private var descriptor: CategoryDescriptor { categoryStore.descriptor(for: item) }
    private var schema: ItemCategory.FieldSchema { descriptor.fieldSchema }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Category badge
                HStack(spacing: 6) {
                    Image(systemName: descriptor.iconName)
                        .font(.system(size: 12, weight: .semibold))
                    Text(descriptor.name)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(descriptor.color)
                .clipShape(Capsule())

                // Fields
                VStack(alignment: .leading, spacing: 10) {
                    MacDetailField(label: schema.titleLabel, value: item.title)

                    if let v = item.subtitle, !v.isEmpty {
                        MacDetailField(label: schema.subtitleLabel ?? "Details", value: v)
                    }
                    if let v = item.link, !v.isEmpty {
                        MacDetailField(
                            label: schema.linkLabel ?? "Link",
                            value: v,
                            isLink: !schema.isLinkEmail,
                            isEmail: schema.isLinkEmail
                        )
                    }
                    if let v = item.extra1, !v.isEmpty {
                        MacDetailField(label: schema.extra1Label ?? "Extra", value: v)
                    }
                    if let v = item.extra2, !v.isEmpty {
                        MacDetailField(label: schema.extra2Label ?? "Extra 2", value: v)
                    }
                    if let v = item.notes, !v.isEmpty {
                        MacDetailField(label: schema.notesLabel ?? "Notes", value: v, multiline: true)
                    }
                }

                // Completion toggle
                if let completionLabel = item.completionLabel {
                    Toggle(completionLabel, isOn: $item.isCompleted)
                        .padding()
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Metadata
                Text("Added: \(item.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Source screenshot
                if let sid = item.sourceScreenshotId {
                    SourceScreenshotCard(screenshotId: sid)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(item.title)
        .toolbar {
            ToolbarItem {
                Button { showEdit = true } label: {
                    Image(systemName: "pencil")
                }
                .help("Edit")
            }
            ToolbarItem {
                Button(role: .destructive) { showDeleteAlert = true } label: {
                    Image(systemName: "trash")
                }
                .help("Delete")
            }
        }
        .sheet(isPresented: $showEdit) {
            MacItemEditView(descriptor: descriptor, item: item)
        }
        .alert("Delete Item?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(item)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This item will be removed from the catalog.")
        }
    }
}

// MARK: - MacDetailField

private struct MacDetailField: View {
    let label: String
    let value: String
    var isLink: Bool = false
    var isEmail: Bool = false
    var multiline: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)

            Group {
                if isLink, let url = URL(string: value.hasPrefix("http") ? value : "https://\(value)") {
                    Link(destination: url) {
                        Text(value)
                            .font(.body)
                            .foregroundStyle(.blue)
                            .lineLimit(multiline ? nil : 3)
                    }
                    .help("Open link")
                } else if isEmail, let url = URL(string: "mailto:\(value)") {
                    Link(destination: url) {
                        Text(value)
                            .font(.body)
                            .foregroundStyle(.blue)
                    }
                } else {
                    Text(value)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(multiline ? nil : 4)
                        .textSelection(.enabled)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - SourceScreenshotCard

private struct SourceScreenshotCard: View {
    let screenshotId: UUID

    @Query private var screenshots: [Screenshot]

    init(screenshotId: UUID) {
        self.screenshotId = screenshotId
        let sid = screenshotId
        _screenshots = Query(filter: #Predicate<Screenshot> { s in s.id == sid })
    }

    var body: some View {
        if let screenshot = screenshots.first {
            HStack(spacing: 12) {
                thumbnailView(screenshot)
                VStack(alignment: .leading, spacing: 3) {
                    Text("SOURCE SCREENSHOT")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                    Text(screenshot.originalFileName ?? "Screenshot")
                        .font(.subheadline)
                    Text(screenshot.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(Color(.controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder
    private func thumbnailView(_ screenshot: Screenshot) -> some View {
        if let data = screenshot.thumbnailData, let img = NSImage(data: data) {
            Image(nsImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        } else {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.secondary.opacity(0.15))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                )
        }
    }
}
