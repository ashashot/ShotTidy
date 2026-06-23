//
//  ManualAddView.swift
//  ShotTidy
//
//  Manual item addition flow: pick a category, fill the form.
//  No AI analysis, no quota — available to all users including free tier.
//

import SwiftUI

struct ManualAddView: View {
    @Environment(\.dismiss)       private var dismiss
    @Environment(CategoryStore.self) private var categoryStore

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    infoBanner
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    Text("Select a category")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(categoryStore.allDescriptors) { descriptor in
                            NavigationLink(value: descriptor) {
                                ManualCategoryCard(descriptor: descriptor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Add Manually")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(for: CategoryDescriptor.self) { descriptor in
                ItemEditView(descriptor: descriptor, item: nil, onSaved: { dismiss() })
            }
        }
    }

    // MARK: - Info banner

    private var infoBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "pencil.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text("Manual Mode — Free for Everyone")
                    .font(.subheadline.weight(.semibold))
                Text("Type information directly. Optionally attach a screenshot.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.blue.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.blue.opacity(0.18), lineWidth: 1)
        )
    }
}

// MARK: - ManualCategoryCard

private struct ManualCategoryCard: View {
    let descriptor: CategoryDescriptor

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: descriptor.iconName)
                .font(.body)
                .foregroundStyle(descriptor.color)
                .frame(width: 32, height: 32)
                .background(descriptor.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(descriptor.name)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
