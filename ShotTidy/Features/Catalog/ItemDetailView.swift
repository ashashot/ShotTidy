//
//  ItemDetailView.swift
//  ShotTidy
//
//  Detailed view for a catalog item.
//

import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Bindable var item: CatalogItem
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showEdit = false
    @State private var showDeleteAlert = false

    private var schema: ItemCategory.FieldSchema { item.category.fieldSchema }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Category badge
                HStack(spacing: 6) {
                    Image(systemName: item.category.icon)
                        .font(.system(size: 13, weight: .semibold))
                    Text(item.category.localizedName)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(item.category.color)
                .clipShape(Capsule())

                // Fields
                VStack(alignment: .leading, spacing: 10) {
                    DetailField(label: schema.titleLabel, value: item.title)

                    if let v = item.subtitle, !v.isEmpty {
                        DetailField(label: schema.subtitleLabel ?? "Details", value: v)
                    }
                    if let v = item.link, !v.isEmpty {
                        DetailField(
                            label: schema.linkLabel ?? "Link",
                            value: v,
                            isLink: !schema.isLinkEmail,
                            isEmail: schema.isLinkEmail
                        )
                    }
                    if let v = item.extra1, !v.isEmpty {
                        DetailField(label: schema.extra1Label ?? "Extra", value: v)
                    }
                    if let v = item.extra2, !v.isEmpty {
                        DetailField(label: schema.extra2Label ?? "Extra 2", value: v)
                    }
                    if let v = item.notes, !v.isEmpty {
                        DetailField(label: schema.notesLabel ?? "Notes", value: v, multiline: true)
                    }
                }

                // Completion toggle for tasks and shopping
                if item.category == .tasks || item.category == .shopping {
                    Toggle(item.category == .tasks ? "Completed" : "Purchased",
                           isOn: $item.isCompleted)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Metadata
                VStack(alignment: .leading, spacing: 4) {
                    Text("Added: \(item.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
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
            ItemEditView(category: item.category, item: item)
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
}

// MARK: - DetailField

private struct DetailField: View {
    let label: String
    let value: String
    var isLink: Bool = false
    var isEmail: Bool = false
    var multiline: Bool = false

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
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
