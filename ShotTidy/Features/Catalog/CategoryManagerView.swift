//
//  CategoryManagerView.swift
//  ShotTidy
//
//  Manage user-defined categories (Pro feature):
//  list, create, edit, and delete. Built-in categories are shown read-only
//  for reference. Creating a category requires an active Pro subscription.
//

import SwiftUI
import SwiftData

struct CategoryManagerView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(SubscriptionManager.self) private var subManager
    @Environment(CategoryStore.self) private var categoryStore

    @Query(sort: [SortDescriptor(\UserCategory.sortOrder), SortDescriptor(\UserCategory.createdAt)])
    private var userCategories: [UserCategory]

    @State private var editorCategory: UserCategory?
    @State private var showNewEditor = false
    @State private var showPaywall = false
    @State private var deleteTarget: UserCategory?

    var body: some View {
        NavigationStack {
            List {
                customSection
                builtInSection
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        startCreate()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showNewEditor) {
                CategoryEditorView()
            }
            .sheet(item: $editorCategory) { category in
                CategoryEditorView(existing: category)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Delete Category?", isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let target = deleteTarget { delete(target) }
                }
                Button("Cancel", role: .cancel) { deleteTarget = nil }
            } message: {
                Text("Items in this category will be kept but shown under \u{201C}\(String(localized: "Other", bundle: AppLocale.bundle))\u{201D}. This cannot be undone.")
            }
        }
    }

    // MARK: - Custom section

    @ViewBuilder
    private var customSection: some View {
        Section {
            if userCategories.isEmpty {
                emptyRow
            } else {
                ForEach(userCategories) { category in
                    Button {
                        editorCategory = category
                    } label: {
                        categoryRow(category.descriptor, showChevron: true)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteTarget = category
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        } header: {
            Text("My Categories")
        } footer: {
            if !subManager.isProActive {
                Text("Custom categories are a Pro feature. The AI will also match and suggest your categories when analyzing screenshots.")
            }
        }
    }

    private var emptyRow: some View {
        HStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text("No custom categories yet")
                    .font(.subheadline)
                Text("Tap + to create one")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Built-in section

    private var builtInSection: some View {
        Section("Built-in") {
            ForEach(categoryStore.builtInDescriptors) { descriptor in
                categoryRow(descriptor, showChevron: false)
            }
        }
    }

    // MARK: - Row

    private func categoryRow(_ descriptor: CategoryDescriptor, showChevron: Bool) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(descriptor.color.opacity(0.15))
                    .frame(width: 34, height: 34)
                Image(systemName: descriptor.iconName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(descriptor.color)
            }
            Text(descriptor.name)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Spacer()
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Actions

    private func startCreate() {
        if subManager.isProActive {
            showNewEditor = true
        } else {
            showPaywall = true
        }
    }

    private func delete(_ category: UserCategory) {
        modelContext.delete(category)
        try? modelContext.save()
        categoryStore.reload()
        deleteTarget = nil
    }
}
