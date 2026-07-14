//
//  MacItemDetailView.swift
//  ShotTidierMac
//

import SwiftUI
import SwiftData

struct MacItemDetailView: View {

    @Bindable var item: CatalogItem
    @Environment(\.modelContext) private var modelContext
    @Environment(CategoryStore.self) private var categoryStore
    @Environment(UsageManager.self) private var usageManager

    @State private var showEdit = false
    @State private var showDeleteAlert = false
    @State private var enrichmentState: EnrichmentState = .idle
    @State private var recentlyFilledKeys: Set<String> = []

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
                    MacDetailField(
                        label: schema.titleLabel,
                        value: item.title,
                        highlighted: recentlyFilledKeys.contains("title")
                    )

                    if let v = item.subtitle, !v.isEmpty {
                        MacDetailField(
                            label: schema.subtitleLabel ?? "Details",
                            value: v,
                            highlighted: recentlyFilledKeys.contains("subtitle")
                        )
                    }
                    if let v = item.link, !v.isEmpty {
                        MacDetailField(
                            label: schema.linkLabel ?? "Link",
                            value: v,
                            isLink: !schema.isLinkEmail,
                            isEmail: schema.isLinkEmail,
                            highlighted: recentlyFilledKeys.contains("link")
                        )
                    }
                    if let v = item.extra1, !v.isEmpty {
                        MacDetailField(
                            label: schema.extra1Label ?? "Extra",
                            value: v,
                            highlighted: recentlyFilledKeys.contains("extra1")
                        )
                    }
                    if let v = item.extra2, !v.isEmpty {
                        MacDetailField(
                            label: schema.extra2Label ?? "Extra 2",
                            value: v,
                            highlighted: recentlyFilledKeys.contains("extra2")
                        )
                    }
                    if let v = item.notes, !v.isEmpty {
                        MacDetailField(
                            label: schema.notesLabel ?? "Notes",
                            value: v,
                            multiline: true,
                            highlighted: recentlyFilledKeys.contains("notes")
                        )
                    }
                }

                // Enrichment button
                if item.hasMissingOptionalFields {
                    enrichmentSection
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

                // Source screenshot card
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

    // MARK: - Enrichment section

    @ViewBuilder
    private var enrichmentSection: some View {
        VStack(spacing: 8) {
            switch enrichmentState {
            case .idle:
                Button(action: runEnrichment) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                        Text("Find Missing Info")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("AI Search · \(usageManager.enrichmentBalance)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(descriptor.color)
                            .clipShape(Capsule())
                    }
                    .foregroundStyle(descriptor.color)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background(descriptor.color.opacity(0.09))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(descriptor.color.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

            case .loading:
                HStack(spacing: 10) {
                    ProgressView().controlSize(.small).tint(descriptor.color)
                    Text("Searching for missing info…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(Color(.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            case .success(let count):
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(count == 1 ? "1 field filled automatically" : "\(count) fields filled automatically")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    if item.hasMissingOptionalFields {
                        Button {
                            withAnimation { enrichmentState = .idle }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.green.opacity(0.25), lineWidth: 1)
                )

            case .failure(let message):
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                        Text(message)
                            .font(.subheadline)
                            .lineLimit(2)
                        Spacer()
                    }
                    Button("Try again") {
                        withAnimation { enrichmentState = .idle }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(descriptor.color)
                    .buttonStyle(.plain)
                }
                .padding(14)
                .background(Color.orange.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Enrichment logic

    private func runEnrichment() {
        guard usageManager.canEnrich() else {
            withAnimation {
                enrichmentState = .failure("No enrichment credits left. Purchase credits to continue.")
            }
            return
        }

        // Deduct one credit before the API call (matches iOS behavior)
        usageManager.consumeEnrichment()

        withAnimation { enrichmentState = .loading }
        recentlyFilledKeys = []

        Task {
            do {
                let result = try await EnrichmentAPIClient.shared.enrich(item, schema: schema)

                var filledKeys: Set<String> = []
                if let v = result.subtitle { item.subtitle = v; filledKeys.insert("subtitle") }
                if let v = result.link     { item.link     = v; filledKeys.insert("link") }
                if let v = result.extra1   { item.extra1   = v; filledKeys.insert("extra1") }
                if let v = result.extra2   { item.extra2   = v; filledKeys.insert("extra2") }
                if let v = result.notes    { item.notes    = v; filledKeys.insert("notes") }

                withAnimation(.spring(duration: 0.4)) {
                    recentlyFilledKeys = filledKeys
                    enrichmentState = .success(result.filledCount)
                }

                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation(.easeOut(duration: 0.5)) {
                        recentlyFilledKeys = []
                    }
                }
            } catch {
                withAnimation {
                    enrichmentState = .failure(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - EnrichmentState

private enum EnrichmentState {
    case idle
    case loading
    case success(Int)
    case failure(String)
}

// MARK: - MacDetailField

private struct MacDetailField: View {
    let label: String
    let value: String
    var isLink: Bool = false
    var isEmail: Bool = false
    var multiline: Bool = false
    var highlighted: Bool = false

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
        .background(
            highlighted
                ? Color.green.opacity(0.12)
                : Color(.controlBackgroundColor)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    highlighted ? Color.green.opacity(0.4) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .animation(.spring(duration: 0.4), value: highlighted)
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
