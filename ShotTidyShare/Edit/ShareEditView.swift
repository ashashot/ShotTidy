//
//  ShareEditView.swift
//  ShotTidyShare
//
//  Edit form for a PendingDraftItem inside the Share Extension.
//  Category names and field schema come from the main app's ItemCategory /
//  CategoryDescriptor (cross-compiled into this target) so both targets stay
//  in sync automatically instead of maintaining a second, drifting copy.
//

import SwiftUI

// MARK: - Category options (picker list + display info)

struct ShareCategoryOption: Identifiable {
    var id: String { key }
    let key: String
    let name: String
    let icon: String

    static let builtIn: [ShareCategoryOption] = ItemCategory.allCases.map {
        .init(key: $0.rawValue, name: $0.localizedName, icon: $0.icon)
    }

    /// Custom categories shared from the main app via the App Group.
    static var custom: [ShareCategoryOption] {
        AppGroupManager.loadCustomCategories().map {
            .init(key: $0.key, name: $0.name, icon: $0.icon)
        }
    }

    /// Built-in categories followed by the user's custom ones.
    static var all: [ShareCategoryOption] {
        builtIn + custom
    }

    // MARK: - Display info (name + icon + color) for the category row chip

    typealias DisplayInfo = (name: String, icon: String, color: Color)

    static func displayInfo(for key: String) -> DisplayInfo {
        if let category = ItemCategory(rawValue: key) {
            return (category.localizedName, category.icon, category.color)
        }
        // Custom category — look it up in the App Group snapshot.
        if let custom = custom.first(where: { $0.key == key }) {
            return (custom.name, custom.icon, Color(red: 0.56, green: 0.56, blue: 0.58))
        }
        return (String(localized: "Other", bundle: AppLocale.bundle), "tag.fill", .gray)
    }
}

// MARK: - Edit View

struct ShareEditView: View {
    @Binding var item: PendingDraftItem
    @Environment(\.dismiss) private var dismiss

    @State private var enrichState: ShareEnrichState = .idle
    @State private var highlightedFields: Set<String> = []

    // Share Extension can't launch a purchase sheet — show balance inline only.
    private var usageManager: ShareUsageManager { ShareUsageManager.shared }

    private var schema: ItemCategory.FieldSchema { ItemCategory.FieldSchema.resolved(for: item.categoryKey) }
    private var categoryColor: Color { ShareCategoryOption.displayInfo(for: item.categoryKey).color }

    /// True when title is set and at least one schema-defined optional field is empty.
    private var hasMissingFields: Bool {
        guard !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        let checks: [(label: String?, value: String)] = [
            (schema.subtitleLabel, item.subtitle),
            (schema.linkLabel,     item.link),
            (schema.extra1Label,   item.extra1),
            (schema.extra2Label,   item.extra2),
            (schema.notesLabel,    item.notes),
        ]
        return checks.contains { label, value in
            label != nil && value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Category
                Section("Category") {
                    Picker("Category", selection: $item.categoryKey) {
                        ForEach(ShareCategoryOption.all) { cat in
                            Label(cat.name, systemImage: cat.icon).tag(cat.key)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Title (always visible)
                Section(schema.titleLabel) {
                    TextField(schema.titlePlaceholder, text: $item.title, axis: .vertical)
                        .lineLimit(4, reservesSpace: false)
                }

                // Subtitle
                if let label = schema.subtitleLabel {
                    Section(label) {
                        TextField(schema.subtitlePlaceholder ?? label, text: $item.subtitle, axis: .vertical)
                            .lineLimit(3, reservesSpace: false)
                            .listRowBackground(
                                highlightedFields.contains("subtitle") ? Color.green.opacity(0.15) : nil
                            )
                    }
                }

                // Link
                if let label = schema.linkLabel {
                    Section(label) {
                        TextField(schema.linkPlaceholder ?? "https://...", text: $item.link)
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
                        TextField(schema.extra1Placeholder ?? label, text: $item.extra1)
                            .listRowBackground(
                                highlightedFields.contains("extra1") ? Color.green.opacity(0.15) : nil
                            )
                    }
                }

                // Extra 2
                if let label = schema.extra2Label {
                    Section(label) {
                        TextField(schema.extra2Placeholder ?? label, text: $item.extra2)
                            .listRowBackground(
                                highlightedFields.contains("extra2") ? Color.green.opacity(0.15) : nil
                            )
                    }
                }

                // Notes
                if let label = schema.notesLabel {
                    Section(label) {
                        TextField(schema.notesPlaceholder ?? label, text: $item.notes, axis: .vertical)
                            .lineLimit(6, reservesSpace: false)
                            .listRowBackground(
                                highlightedFields.contains("notes") ? Color.green.opacity(0.15) : nil
                            )
                    }
                }

                // Fill Missing Fields button — inline in the form
                if enrichState == .idle && hasMissingFields {
                    if usageManager.canEnrich() {
                        Section {
                            Button(action: runEnrichment) {
                                HStack(spacing: 10) {
                                    Image(systemName: "magnifyingglass.circle.fill")
                                        .font(.system(size: 18, weight: .semibold))
                                    Text("Fill Missing Fields")
                                        .fontWeight(.semibold)
                                        .font(.system(size: 16))
                                    Spacer()
                                    Text("\(usageManager.enrichmentBalance)")
                                        .font(.system(size: 12, weight: .bold))
                                        .monospacedDigit()
                                        .padding(.horizontal, 9)
                                        .padding(.vertical, 4)
                                        .background(.white.opacity(0.25))
                                        .clipShape(Capsule())
                                }
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 44)
                            }
                            .listRowBackground(
                                LinearGradient(
                                    colors: [
                                        Color(red: 1.0, green: 0.45, blue: 0.0),
                                        Color(red: 1.0, green: 0.28, blue: 0.0),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        }
                    } else {
                        Section {
                            HStack(spacing: 10) {
                                Image(systemName: "cart.circle.fill")
                                    .foregroundStyle(.secondary)
                                Text("No enrichment credits left. Open ShotTidier to buy more.")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .frame(minHeight: 44)
                        }
                    }
                }
            }
            // Status bar — shown only while enrichment is active (loading / success / error)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if enrichState != .idle {
                    shareEnrichStatusBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.3), value: enrichState == .idle)
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Done — top RIGHT
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Status bar (bottom)

    @ViewBuilder
    private var shareEnrichStatusBar: some View {
        VStack(spacing: 0) {
            Divider()
            Group {
                switch enrichState {
                case .idle:
                    EmptyView()

                case .loading:
                    HStack(spacing: 12) {
                        ProgressView().tint(categoryColor)
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
                        Text("\(count) fields filled — review and tap Done")
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
                            .foregroundStyle(categoryColor)
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
        // Safety guard — button should already be hidden, but double-check
        guard usageManager.canEnrich() else { return }

        // Consume one credit before the API call
        usageManager.consumeEnrichment()

        withAnimation { enrichState = .loading }
        highlightedFields = []

        Task {
            do {
                let result = try await ShareEnrichmentClient.shared.enrich(
                    item: item,
                    schema: schema
                )

                var filled = 0
                var keys = Set<String>()

                if let v = result.subtitle, item.subtitle.isEmpty { item.subtitle = v; filled += 1; keys.insert("subtitle") }
                if let v = result.link,     item.link.isEmpty     { item.link     = v; filled += 1; keys.insert("link") }
                if let v = result.extra1,   item.extra1.isEmpty   { item.extra1   = v; filled += 1; keys.insert("extra1") }
                if let v = result.extra2,   item.extra2.isEmpty   { item.extra2   = v; filled += 1; keys.insert("extra2") }
                if let v = result.notes,    item.notes.isEmpty    { item.notes    = v; filled += 1; keys.insert("notes") }

                withAnimation(.spring(duration: 0.35)) {
                    highlightedFields = keys
                    enrichState = filled > 0 ? .success(filled) : .failure("No additional info found.")
                }

                Task {
                    try? await Task.sleep(for: .seconds(4))
                    withAnimation(.easeOut(duration: 0.6)) { highlightedFields = [] }
                }

            } catch {
                withAnimation { enrichState = .failure(error.localizedDescription) }
            }
        }
    }

}

// MARK: - ShareEnrichState

private enum ShareEnrichState: Equatable {
    case idle
    case loading
    case success(Int)
    case failure(String)
}
