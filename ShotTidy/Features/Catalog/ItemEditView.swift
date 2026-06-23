//
//  ItemEditView.swift
//  ShotTidy
//
//  Screen for adding or editing a catalog item.
//  Performs real-time duplicate detection while the user types.
//  Shows a sticky "Find Missing Info" bar at the bottom when optional fields are empty.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ItemEditView: View {
    let descriptor: CategoryDescriptor
    var existingItem: CatalogItem?
    /// Called after a successful save. When nil, the default dismiss() is used.
    var onSaved: (() -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @Environment(SubscriptionManager.self) private var subManager
    @Environment(UsageManager.self)        private var usageManager

    @State private var title: String
    @State private var subtitle: String
    @State private var link: String
    @State private var extra1: String
    @State private var extra2: String
    @State private var notes: String

    // MARK: - Manual screenshot attachment
    @State private var manualPhoto: UIImage?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var showCamera = false

    // MARK: - Duplicate detection
    @State private var duplicates: [DuplicateMatch] = []
    @State private var showDuplicateConfirm  = false

    // MARK: - Paywall / store
    @State private var showEnrichmentStore   = false

    // MARK: - Enrichment state
    @State private var enrichState: EditEnrichState = .idle
    @State private var highlightedFields: Set<String> = []

    init(descriptor: CategoryDescriptor, item: CatalogItem?, attachedImage: UIImage? = nil, onSaved: (() -> Void)? = nil) {
        self.descriptor = descriptor
        self.existingItem = item
        self.onSaved = onSaved
        _title    = State(initialValue: item?.title ?? "")
        _subtitle = State(initialValue: item?.subtitle ?? "")
        _link     = State(initialValue: item?.link ?? "")
        _extra1   = State(initialValue: item?.extra1 ?? "")
        _extra2   = State(initialValue: item?.extra2 ?? "")
        _notes    = State(initialValue: item?.notes ?? "")
        _manualPhoto = State(initialValue: attachedImage)
    }

    private var isEditing: Bool { existingItem != nil }
    private var schema: ItemCategory.FieldSchema { descriptor.fieldSchema }
    private var canSave: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// True when the title is filled and at least one schema-defined optional field is empty.
    private var hasMissingLocalFields: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        let checks: [(label: String?, value: String)] = [
            (schema.subtitleLabel, subtitle),
            (schema.linkLabel,     link),
            (schema.extra1Label,   extra1),
            (schema.extra2Label,   extra2),
            (schema.notesLabel,    notes),
        ]
        return checks.contains { label, value in
            label != nil && value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private var duplicateCheckKey: String { "\(title)|\(subtitle)|\(link)" }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Screenshot attachment (only for new items)
                if !isEditing {
                    Section {
                        screenshotAttachmentRow
                    } header: {
                        Text("Screenshot (Optional)")
                    }
                }

                // Title (required)
                Section {
                    TextField(schema.titlePlaceholder, text: $title, axis: .vertical)
                        .lineLimit(3, reservesSpace: false)
                } header: {
                    Text(schema.titleLabel)
                } footer: {
                    if title.isEmpty {
                        Text("Required field").foregroundStyle(.red)
                    }
                }

                // Duplicate warning
                if !duplicates.isEmpty { duplicateWarningSection }

                // Subtitle
                if let label = schema.subtitleLabel {
                    Section(label) {
                        TextField(schema.subtitlePlaceholder ?? "", text: $subtitle, axis: .vertical)
                            .lineLimit(4, reservesSpace: false)
                            .listRowBackground(
                                highlightedFields.contains("subtitle") ? Color.green.opacity(0.15) : nil
                            )
                    }
                }

                // Link
                if let label = schema.linkLabel {
                    Section(label) {
                        TextField(schema.linkPlaceholder ?? "https://...", text: $link)
                            .keyboardType(schema.isLinkEmail ? .emailAddress : .URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .listRowBackground(
                                highlightedFields.contains("link") ? Color.green.opacity(0.15) : nil
                            )
                    }
                }

                // Extra 1
                if let label = schema.extra1Label {
                    Section(label) {
                        TextField(schema.extra1Placeholder ?? "", text: $extra1)
                            .listRowBackground(
                                highlightedFields.contains("extra1") ? Color.green.opacity(0.15) : nil
                            )
                    }
                }

                // Extra 2
                if let label = schema.extra2Label {
                    Section(label) {
                        TextField(schema.extra2Placeholder ?? "", text: $extra2)
                            .listRowBackground(
                                highlightedFields.contains("extra2") ? Color.green.opacity(0.15) : nil
                            )
                    }
                }

                // Notes
                if let label = schema.notesLabel {
                    Section(label) {
                        TextField(schema.notesPlaceholder ?? label, text: $notes, axis: .vertical)
                            .lineLimit(6, reservesSpace: false)
                            .listRowBackground(
                                highlightedFields.contains("notes") ? Color.green.opacity(0.15) : nil
                            )
                    }
                }

                // Source screenshot (read-only, shown when item was created from import)
                if let screenshotId = existingItem?.sourceScreenshotId {
                    Section("Source Screenshot") {
                        SourceScreenshotRow(screenshotId: screenshotId)
                    }
                }
            }
            // Status bar — shown only while search is active (loading / success / error)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if enrichState != .idle {
                    enrichmentStatusBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3), value: enrichState == .idle)
            .navigationTitle(isEditing ? "Edit" : "Add")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel — top LEFT
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                // Search — top RIGHT (before Save), shown when fields are missing
                ToolbarItem(placement: .topBarTrailing) {
                    if hasMissingLocalFields && enrichState == .idle {
                        Button(action: runEnrichment) {
                            HStack(spacing: 4) {
                                Image(systemName: usageManager.enrichmentBalance > 0
                                      ? "magnifyingglass.circle.fill"
                                      : "cart.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(descriptor.color)
                                if usageManager.enrichmentBalance > 0 {
                                    Text("\(usageManager.enrichmentBalance)")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundStyle(descriptor.color)
                                }
                            }
                        }
                    }
                }
                // Save — top RIGHT (rightmost)
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !isEditing && !duplicates.isEmpty {
                            showDuplicateConfirm = true
                        } else {
                            doSave()
                        }
                    }
                    .disabled(!canSave)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showEnrichmentStore) {
                EnrichmentStoreView()
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPickerView(image: $manualPhoto)
                    .ignoresSafeArea()
            }
            .alert("Possible Duplicate", isPresented: $showDuplicateConfirm) {
                Button("Save Anyway", role: .destructive) { doSave() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(duplicateAlertMessage)
            }
            .task(id: duplicateCheckKey) {
                guard canSave else { duplicates = []; return }
                try? await Task.sleep(for: .milliseconds(400))
                guard !Task.isCancelled else { return }
                duplicates = DuplicateChecker.findDuplicates(
                    for: title,
                    subtitle: subtitle.isEmpty ? nil : subtitle,
                    link: link.isEmpty ? nil : link,
                    categoryKey: descriptor.key,
                    excludingId: existingItem?.id,
                    in: modelContext
                )
            }
        }
    }

    // MARK: - Status bar (bottom, shown only during active search)

    @ViewBuilder
    private var enrichmentStatusBar: some View {
        VStack(spacing: 0) {
            Divider()
            Group {
                switch enrichState {
                case .idle:
                    EmptyView()

                case .loading:
                    HStack(spacing: 12) {
                        ProgressView().tint(descriptor.color)
                        Text("Searching the web…")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)

                case .success(let count):
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text(count == 1
                             ? "1 field filled — review and save"
                             : "\(count) fields filled — review and save")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)

                case .failure(let message):
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
                        Text(message)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(2)
                        Spacer()
                        Button("Retry") { withAnimation { enrichState = .idle } }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(descriptor.color)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                }
            }
            .background(.bar)
        }
    }

    // MARK: - Enrichment logic

    private func runEnrichment() {
        // Gate on credit balance
        guard usageManager.canEnrich() else {
            showEnrichmentStore = true
            return
        }

        // Consume one credit before the API call
        usageManager.consumeEnrichment()

        withAnimation { enrichState = .loading }
        highlightedFields = []

        Task {
            do {
                let result = try await EnrichmentAPIClient.shared.enrichFields(
                    categoryKey: descriptor.key,
                    title: title,
                    subtitle: subtitle,
                    link: link,
                    extra1: extra1,
                    extra2: extra2,
                    notes: notes,
                    schema: schema
                )

                var filled = 0
                var keys = Set<String>()

                if let v = result.subtitle, subtitle.isEmpty { subtitle = v; filled += 1; keys.insert("subtitle") }
                if let v = result.link,     link.isEmpty     { link     = v; filled += 1; keys.insert("link") }
                if let v = result.extra1,   extra1.isEmpty   { extra1   = v; filled += 1; keys.insert("extra1") }
                if let v = result.extra2,   extra2.isEmpty   { extra2   = v; filled += 1; keys.insert("extra2") }
                if let v = result.notes,    notes.isEmpty    { notes    = v; filled += 1; keys.insert("notes") }

                withAnimation(.spring(duration: 0.35)) {
                    highlightedFields = keys
                    enrichState = filled > 0 ? .success(filled) : .failure("No additional info found.")
                }

                // Fade highlight after 4 s
                Task {
                    try? await Task.sleep(for: .seconds(4))
                    withAnimation(.easeOut(duration: 0.6)) { highlightedFields = [] }
                }

            } catch {
                withAnimation { enrichState = .failure(error.localizedDescription) }
            }
        }
    }

    // MARK: - Duplicate warning

    @ViewBuilder
    private var duplicateWarningSection: some View {
        Section {
            ForEach(duplicates) { match in
                HStack(spacing: 10) {
                    Image(systemName: match.confidence.icon)
                        .foregroundStyle(match.confidence.color)
                        .font(.subheadline)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(match.item.title)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                        if let sub = match.item.subtitle {
                            Text(sub).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                        }
                        Text(match.reason).font(.caption2).foregroundStyle(match.confidence.color)
                    }
                    Spacer()
                }
                .padding(.vertical, 2)
            }
            .listRowBackground(Color.orange.opacity(0.07))
        } header: {
            HStack(spacing: 5) {
                Image(systemName: "exclamationmark.triangle.fill").font(.caption)
                Text(duplicates.count == 1 ? "Possible Duplicate" : "Possible Duplicates (\(duplicates.count))")
            }
            .foregroundStyle(.orange)
        } footer: {
            Text("You can still save — duplicates are shown as a warning only.").foregroundStyle(.secondary)
        }
    }

    // MARK: - Alert message

    private var duplicateAlertMessage: String {
        let names = duplicates.prefix(2).map { "\u{201C}\($0.item.title)\u{201D}" }.joined(separator: ", ")
        return duplicates.count == 1
            ? "An item with the same title already exists: \(names). Save anyway?"
            : "\(duplicates.count) similar items already exist: \(names)\(duplicates.count > 2 ? "…" : ""). Save anyway?"
    }

    // MARK: - Save

    private func doSave() {
        save()
        if let onSaved {
            onSaved()
        } else {
            dismiss()
        }
    }

    private func save() {
        if let existing = existingItem {
            existing.title    = title.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.subtitle = subtitle.isEmpty ? nil : subtitle
            existing.link     = link.isEmpty ? nil : link
            existing.extra1   = extra1.isEmpty ? nil : extra1
            existing.extra2   = extra2.isEmpty ? nil : extra2
            existing.notes    = notes.isEmpty ? nil : notes
        } else {
            var sourceId: UUID? = nil
            if let image = manualPhoto {
                let screenshot = Screenshot()
                screenshot.originalFileName = "manual_screenshot.jpg"
                screenshot.createdAt = Date()
                screenshot.analysisStatus = .done
                screenshot.extractedItemsCount = 1
                let thumb = image.resized(toMaxDimension: 800)
                screenshot.thumbnailData = thumb.jpegData(compressionQuality: 0.85)
                modelContext.insert(screenshot)
                sourceId = screenshot.id
            }
            let item = CatalogItem(
                categoryKey: descriptor.key,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                subtitle: subtitle.isEmpty ? nil : subtitle,
                link: link.isEmpty ? nil : link,
                extra1: extra1.isEmpty ? nil : extra1,
                extra2: extra2.isEmpty ? nil : extra2,
                notes: notes.isEmpty ? nil : notes,
                sourceScreenshotId: sourceId
            )
            modelContext.insert(item)
        }
    }

    // MARK: - Screenshot attachment UI

    @ViewBuilder
    private var screenshotAttachmentRow: some View {
        if let photo = manualPhoto {
            HStack(spacing: 12) {
                Image(uiImage: photo)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .clipped()

                VStack(alignment: .leading, spacing: 3) {
                    Text("Screenshot attached")
                        .font(.subheadline)
                    Text("Will be saved with this item as a reference")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(role: .destructive) {
                    withAnimation { manualPhoto = nil; photoPickerItem = nil }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 4)
        } else {
            HStack(spacing: 12) {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    Label("Gallery", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .onChange(of: photoPickerItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let img = UIImage(data: data) {
                            manualPhoto = img
                        }
                    }
                }

                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }
}

// MARK: - SourceScreenshotRow

private struct SourceScreenshotRow: View {
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
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tap to view original screenshot")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Text(screenshot.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func thumbnailView(_ screenshot: Screenshot) -> some View {
        if let data = screenshot.thumbnailData, let img = UIImage(data: data) {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 7))
        } else {
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(.tertiarySystemFill))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "photo")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                )
        }
    }
}

// MARK: - EditEnrichState

private enum EditEnrichState: Equatable {
    case idle
    case loading
    case success(Int)
    case failure(String)
}

// MARK: - CameraPickerView

private struct CameraPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(image: $image, dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        @Binding var image: UIImage?
        let dismiss: DismissAction

        init(image: Binding<UIImage?>, dismiss: DismissAction) {
            _image = image
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            image = info[.originalImage] as? UIImage
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
