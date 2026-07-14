//
//  CategoryEditorView.swift
//  ShotTidy
//
//  Create or edit a user-defined category (Pro feature).
//  Lets the user pick a name, icon, color, and field labels — with an
//  optional AI-powered field-layout suggestion (metered, 5 per period).
//

import SwiftUI
import SwiftData

struct CategoryEditorView: View {

    /// Existing category when editing; nil when creating.
    var existing: UserCategory?
    /// Optional name to prefill (used when creating from an AI suggestion).
    var prefillName: String = ""
    /// Called with the saved category's key after a successful save.
    var onSaved: ((String) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subManager
    @Environment(UsageManager.self) private var usageManager
    @Environment(CategoryStore.self) private var categoryStore

    // MARK: - Form state
    @State private var name: String
    @State private var iconName: String
    @State private var colorHex: String
    @State private var aiHint: String

    @State private var titleLabel: String
    @State private var subtitleLabel: String
    @State private var linkLabel: String
    @State private var extra1Label: String
    @State private var extra2Label: String
    @State private var notesLabel: String

    // MARK: - AI suggestion state
    @State private var suggestState: SuggestState = .idle
    @State private var showPaywall = false

    private let iconColumns = [GridItem(.adaptive(minimum: 44), spacing: 12)]
    private let colorColumns = [GridItem(.adaptive(minimum: 44), spacing: 14)]

    // MARK: - Init

    init(
        existing: UserCategory? = nil,
        prefillName: String = "",
        onSaved: ((String) -> Void)? = nil
    ) {
        self.existing = existing
        self.prefillName = prefillName
        self.onSaved = onSaved

        _name      = State(initialValue: existing?.name ?? prefillName)
        _iconName  = State(initialValue: existing?.iconName ?? CategoryStyleOptions.defaultIcon)
        _colorHex  = State(initialValue: existing?.colorHex ?? CategoryStyleOptions.defaultColorHex)
        _aiHint    = State(initialValue: existing?.aiHint ?? "")
        _titleLabel    = State(initialValue: existing?.titleLabel ?? "Title")
        _subtitleLabel = State(initialValue: existing?.subtitleLabel ?? "")
        _linkLabel     = State(initialValue: existing?.linkLabel ?? "")
        _extra1Label   = State(initialValue: existing?.extra1Label ?? "")
        _extra2Label   = State(initialValue: existing?.extra2Label ?? "")
        _notesLabel    = State(initialValue: existing?.notesLabel ?? "")
    }

    private var isEditing: Bool { existing != nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedName.isEmpty }
    private var selectedColor: Color { Color(hex: colorHex) }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                previewSection
                nameSection
                iconSection
                colorSection
                fieldsSection
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if suggestState != .idle { suggestStatusBar }
            }
            .animation(.spring(duration: 0.3), value: suggestState == .idle)
            .navigationTitle(isEditing ? "Edit Category" : "New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        Section {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(selectedColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: iconName)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(selectedColor)
                }
                Text(trimmedName.isEmpty ? "Category Name" : trimmedName)
                    .font(.headline)
                    .foregroundStyle(trimmedName.isEmpty ? .secondary : .primary)
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Name

    private var nameSection: some View {
        Section {
            TextField("e.g. Wines, Gym Workouts", text: $name)
        } header: {
            Text("Name")
        } footer: {
            if trimmedName.isEmpty {
                Text("Required").foregroundStyle(.red)
            }
        }
    }

    // MARK: - Icon

    private var iconSection: some View {
        Section("Icon") {
            LazyVGrid(columns: iconColumns, spacing: 12) {
                ForEach(CategoryStyleOptions.icons, id: \.self) { symbol in
                    Button {
                        iconName = symbol
                    } label: {
                        Image(systemName: symbol)
                            .font(.system(size: 18))
                            .foregroundStyle(iconName == symbol ? .white : selectedColor)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle().fill(iconName == symbol ? selectedColor : selectedColor.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Color

    private var colorSection: some View {
        Section("Color") {
            LazyVGrid(columns: colorColumns, spacing: 14) {
                ForEach(CategoryStyleOptions.colors, id: \.self) { color in
                    let hex = color.toHex()
                    Button {
                        colorHex = hex
                    } label: {
                        Circle()
                            .fill(color)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle().stroke(Color.primary, lineWidth: colorHex == hex ? 3 : 0)
                            )
                            .overlay(
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .opacity(colorHex == hex ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Fields

    private var fieldsSection: some View {
        Section {
            labeledField(String(localized: "Primary field (required)", bundle: AppLocale.bundle), text: $titleLabel, placeholder: String(localized: "Title", bundle: AppLocale.bundle))
            labeledField(String(localized: "Second field", bundle: AppLocale.bundle), text: $subtitleLabel, placeholder: String(localized: "Leave empty to hide", bundle: AppLocale.bundle))
            labeledField(String(localized: "Link field", bundle: AppLocale.bundle), text: $linkLabel, placeholder: String(localized: "Leave empty to hide", bundle: AppLocale.bundle))
            labeledField(String(localized: "Third field", bundle: AppLocale.bundle), text: $extra1Label, placeholder: String(localized: "Leave empty to hide", bundle: AppLocale.bundle))
            labeledField(String(localized: "Fourth field", bundle: AppLocale.bundle), text: $extra2Label, placeholder: String(localized: "Leave empty to hide", bundle: AppLocale.bundle))
            labeledField(String(localized: "Notes field", bundle: AppLocale.bundle), text: $notesLabel, placeholder: String(localized: "Leave empty to hide", bundle: AppLocale.bundle))
            TextField("AI sorting hint (optional)", text: $aiHint, axis: .vertical)
                .lineLimit(2, reservesSpace: false)
        } header: {
            HStack {
                Text("Fields")
                Spacer()
                aiSuggestButton
            }
        } footer: {
            Text("Field labels define the form for items in this category. Empty fields are hidden. The AI hint helps automatic sorting during screenshot analysis.")
        }
    }

    private func labeledField(_ label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased(with: .current))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
        }
        .padding(.vertical, 2)
    }

    // MARK: - AI suggest button

    private var aiSuggestButton: some View {
        let remaining = usageManager.remainingCategorySuggestions(isPro: subManager.isProActive)
        return Button {
            runSuggestion()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                Text(remaining > 0 ? "AI fields (\(remaining))" : "AI fields")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.purple)
        }
        .buttonStyle(.plain)
        .disabled(suggestState == .loading || trimmedName.isEmpty)
    }

    // MARK: - Status bar

    @ViewBuilder
    private var suggestStatusBar: some View {
        VStack(spacing: 0) {
            Divider()
            Group {
                switch suggestState {
                case .idle:
                    EmptyView()
                case .loading:
                    HStack(spacing: 12) {
                        ProgressView().tint(.purple)
                        Text("Designing fields…").font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                    }
                case .success:
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text("Fields suggested — review and adjust").font(.subheadline.weight(.medium))
                        Spacer()
                    }
                case .failure(let message):
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.circle.fill").foregroundStyle(.orange)
                        Text(message).font(.subheadline).lineLimit(2)
                        Spacer()
                        Button("OK") { withAnimation { suggestState = .idle } }
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.bar)
        }
    }

    // MARK: - AI suggestion logic

    private func runSuggestion() {
        guard subManager.isProActive else { showPaywall = true; return }
        guard usageManager.canSuggestCategoryFields(isPro: subManager.isProActive) else {
            withAnimation {
                suggestState = .failure(String(localized: "You've used all AI field suggestions for this period.", bundle: AppLocale.bundle))
            }
            return
        }

        usageManager.consumeCategorySuggestion()
        withAnimation { suggestState = .loading }

        Task {
            do {
                let layout = try await CategorySuggestionClient.shared.suggestFields(
                    name: trimmedName,
                    hint: aiHint
                )
                withAnimation(.spring(duration: 0.35)) {
                    iconName      = layout.iconName
                    titleLabel    = layout.titleLabel
                    subtitleLabel = layout.subtitleLabel
                    linkLabel     = layout.linkLabel
                    extra1Label   = layout.extra1Label
                    extra2Label   = layout.extra2Label
                    notesLabel    = layout.notesLabel
                    if aiHint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        aiHint = layout.aiHint
                    }
                    suggestState = .success
                }
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    withAnimation { if suggestState == .success { suggestState = .idle } }
                }
            } catch {
                withAnimation { suggestState = .failure(error.localizedDescription) }
            }
        }
    }

    // MARK: - Save

    private func save() {
        if let existing {
            existing.name = trimmedName
            existing.iconName = iconName
            existing.colorHex = colorHex
            existing.aiHint = aiHint.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.titleLabel = titleLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Title" : titleLabel
            existing.subtitleLabel = subtitleLabel
            existing.linkLabel = linkLabel
            existing.extra1Label = extra1Label
            existing.extra2Label = extra2Label
            existing.notesLabel = notesLabel
            try? modelContext.save()
            categoryStore.reload()
            onSaved?(existing.key)
        } else {
            let category = UserCategory(
                name: trimmedName,
                iconName: iconName,
                colorHex: colorHex,
                sortOrder: categoryStore.nextSortOrder,
                aiHint: aiHint.trimmingCharacters(in: .whitespacesAndNewlines),
                titleLabel: titleLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Title" : titleLabel,
                subtitleLabel: subtitleLabel,
                linkLabel: linkLabel,
                extra1Label: extra1Label,
                extra2Label: extra2Label,
                notesLabel: notesLabel
            )
            modelContext.insert(category)
            try? modelContext.save()
            categoryStore.reload()
            onSaved?(category.key)
        }
        dismiss()
    }

    // MARK: - SuggestState

    private enum SuggestState: Equatable {
        case idle
        case loading
        case success
        case failure(String)
    }
}
