//
//  ItemDetailView.swift
//  ShotTidy
//
//  Detailed view for a catalog item.
//  Includes an "Enrich" button that uses GPT-4o web search to fill empty fields.
//

import SwiftUI
import SwiftData
import MapKit
import EventKitUI

struct ItemDetailView: View {
    @Bindable var item: CatalogItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @Environment(SubscriptionManager.self) private var subManager
    @Environment(UsageManager.self)        private var usageManager
    @Environment(CategoryStore.self)       private var categoryStore

    @State private var showEdit = false
    @State private var showDeleteAlert = false
    @State private var showEnrichmentStore = false

    // MARK: - Calendar state
    @ObservedObject private var calendarService: CalendarService = CalendarService.shared

    // MARK: - Enrichment state
    @State private var enrichmentState: EnrichmentState = .idle
    /// Keys of fields that were just filled by enrichment — used to animate them.
    @State private var recentlyFilledKeys: Set<String> = []

    private var descriptor: CategoryDescriptor { categoryStore.descriptor(for: item) }
    private var schema: ItemCategory.FieldSchema { descriptor.fieldSchema }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Category badge
                HStack(spacing: 6) {
                    Image(systemName: descriptor.iconName)
                        .font(.system(size: 13, weight: .semibold))
                    Text(descriptor.name)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(descriptor.color)
                .clipShape(Capsule())

                // Fields
                VStack(alignment: .leading, spacing: 10) {
                    DetailField(
                        label: schema.titleLabel,
                        value: item.title,
                        highlighted: recentlyFilledKeys.contains("title")
                    )

                    if let v = item.subtitle, !v.isEmpty {
                        DetailField(
                            label: schema.subtitleLabel ?? "Details",
                            value: v,
                            highlighted: recentlyFilledKeys.contains("subtitle")
                        )
                    }
                    if let v = item.link, !v.isEmpty {
                        DetailField(
                            label: schema.linkLabel ?? "Link",
                            value: v,
                            isLink: !schema.isLinkEmail,
                            isEmail: schema.isLinkEmail,
                            highlighted: recentlyFilledKeys.contains("link")
                        )
                    }
                    if let v = item.extra1, !v.isEmpty {
                        DetailField(
                            label: schema.extra1Label ?? "Extra",
                            value: v,
                            highlighted: recentlyFilledKeys.contains("extra1")
                        )
                    }
                    if let v = item.extra2, !v.isEmpty {
                        DetailField(
                            label: schema.extra2Label ?? "Extra 2",
                            value: v,
                            highlighted: recentlyFilledKeys.contains("extra2")
                        )
                    }
                    if let v = item.notes, !v.isEmpty {
                        DetailField(
                            label: schema.notesLabel ?? "Notes",
                            value: v,
                            multiline: true,
                            highlighted: recentlyFilledKeys.contains("notes")
                        )
                    }
                }

                // Add to Calendar button — shown when any field contains a parseable date
                if item.calendarDate != nil {
                    AddToCalendarButton(color: descriptor.color) {
                        calendarService.addToCalendar(item: item)
                    }
                }

                // Map — shown only for the "places" category
                if item.categoryRaw == ItemCategory.places.rawValue {
                    PlaceMapView(
                        placeName: item.title,
                        address: item.subtitle,
                        city: item.extra1,
                        country: item.extra2
                    )
                }

                // Enrichment button — only when some optional fields are empty
                if item.hasMissingOptionalFields {
                    enrichmentSection
                }

                // Completion toggle for tasks and shopping
                if let completionLabel = item.completionLabel {
                    Toggle(completionLabel, isOn: $item.isCompleted)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onChange(of: item.isCompleted) {
                            WidgetDataManager.writeSnapshot(context: modelContext)
                        }
                }

                // Metadata
                VStack(alignment: .leading, spacing: 4) {
                    Text("Added: \(item.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)

                // Source screenshot
                if let screenshotId = item.sourceScreenshotId {
                    SourceScreenshotCard(screenshotId: screenshotId)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Edit") { showEdit = true }
                    Divider()
                    Button("Delete", role: .destructive) { showDeleteAlert = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            ItemEditView(descriptor: descriptor, item: item)
        }
        .sheet(isPresented: $showEnrichmentStore) {
            EnrichmentStoreView()
        }
        .sheet(isPresented: $calendarService.showEditor) {
            if calendarService.pendingEvent != nil {
                CalendarEventEditorView(service: calendarService) {
                    calendarService.showEditor = false
                }
                .ignoresSafeArea()
            }
        }
        .alert("Calendar Access Denied", isPresented: $calendarService.showDeniedAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow ShotTidy to access your calendar in Settings.")
        }
        .alert("Delete item?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                modelContext.delete(item)
                dismiss()
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
                EnrichButton(
                    color: descriptor.color,
                    balance: usageManager.enrichmentBalance
                ) {
                    runEnrichment()
                }

            case .loading:
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(descriptor.color)
                    Text("Searching for missing info…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            case .success(let count):
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(count == 1
                         ? "1 field filled automatically"
                         : "\(count) fields filled automatically")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    Spacer()
                    // Allow re-searching if there are still empty fields
                    if item.hasMissingOptionalFields {
                        Button {
                            withAnimation { enrichmentState = .idle }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.green.opacity(0.25), lineWidth: 1)
                )

            case .failure(let message):
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                    }
                    Button("Try again") {
                        withAnimation { enrichmentState = .idle }
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(descriptor.color)
                }
                .padding(14)
                .background(Color.orange.opacity(0.07))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }

    // MARK: - Enrichment logic

    private func runEnrichment() {
        // Check credits balance first
        guard usageManager.canEnrich() else {
            showEnrichmentStore = true
            return
        }

        // Deduct one credit before the API call
        usageManager.consumeEnrichment()

        withAnimation { enrichmentState = .loading }
        recentlyFilledKeys = []

        Task {
            do {
                let result = try await EnrichmentAPIClient.shared.enrich(item, schema: schema)

                // Apply non-nil results to the item
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

                // Fade out highlight after 3 seconds
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation(.easeOut(duration: 0.5)) {
                        recentlyFilledKeys = []
                    }
                }

            } catch {
                withAnimation {
                    enrichmentState = .failure(
                        error.localizedDescription
                    )
                }
            }
        }
    }
}

// MARK: - EnrichmentState

private enum EnrichmentState {
    case idle
    case loading
    case success(Int)   // number of fields filled
    case failure(String)
}

// MARK: - EnrichButton

private struct EnrichButton: View {
    let color: Color
    let balance: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: balance > 0
                      ? "magnifyingglass.circle.fill"
                      : "cart.circle.fill")
                    .font(.system(size: 16, weight: .semibold))

                Text(balance > 0 ? "Find Missing Info" : "Buy Enrichment Credits")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                // Credit badge
                if balance > 0 {
                    Text("\(balance)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(color)
                        .clipShape(Capsule())
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(color.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SourceScreenshotCard

struct SourceScreenshotCard: View {
    let screenshotId: UUID

    @Query private var screenshots: [Screenshot]

    init(screenshotId: UUID) {
        self.screenshotId = screenshotId
        let sid = screenshotId
        _screenshots = Query(filter: #Predicate<Screenshot> { s in s.id == sid })
    }

    var body: some View {
        if let screenshot = screenshots.first {
            NavigationLink(destination: ScreenshotDetailView(screenshot: screenshot)) {
                HStack(spacing: 12) {
                    thumbnailView(screenshot)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("SOURCE SCREENSHOT")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                        Text("View screenshot")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Text(screenshot.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .buttonStyle(.plain)
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    @ViewBuilder
    private func thumbnailView(_ screenshot: Screenshot) -> some View {
        if let data = screenshot.thumbnailData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: 54, height: 54)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.tertiarySystemGroupedBackground))
                .frame(width: 54, height: 54)
                .overlay(
                    Image(systemName: "photo")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                )
        }
    }
}

// MARK: - AddToCalendarButton

private struct AddToCalendarButton: View {
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 16, weight: .semibold))
                Text("Add to Calendar")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(color)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(color.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - DetailField

private struct DetailField: View {
    let label: String
    let value: String
    var isLink: Bool = false
    var isEmail: Bool = false
    var multiline: Bool = false
    var highlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
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
        .padding(14)
        .background(
            highlighted
                ? Color.green.opacity(0.12)
                : Color(.secondarySystemGroupedBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    highlighted ? Color.green.opacity(0.4) : Color.clear,
                    lineWidth: 1.5
                )
        )
        .animation(.spring(duration: 0.4), value: highlighted)
    }
}
