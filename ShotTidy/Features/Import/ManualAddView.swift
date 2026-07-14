//
//  ManualAddView.swift
//  ShotTidy
//
//  Manual item addition flow: pick a category, then fill the form.
//  No AI analysis, no quota — available to all users including free tier.
//
//  Navigation note: ItemEditView owns its own NavigationStack (it's also used
//  as a standalone sheet). Pushing it via navigationDestination would nest two
//  NavigationStacks (flicker + instant pop). We present it as a sheet instead.
//

import SwiftUI

struct ManualAddView: View {
    @Environment(\.dismiss)         private var dismiss
    @Environment(CategoryStore.self) private var categoryStore

    @State private var selectedDescriptor: CategoryDescriptor?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    infoBanner
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section("Select a category") {
                    ForEach(categoryStore.allDescriptors) { descriptor in
                        Button {
                            selectedDescriptor = descriptor
                        } label: {
                            ManualCategoryRow(descriptor: descriptor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Add Manually")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(item: $selectedDescriptor) { descriptor in
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
        .padding(.horizontal, 4)
        .padding(.vertical, 4)
    }
}

// MARK: - ManualCategoryRow

private struct ManualCategoryRow: View {
    let descriptor: CategoryDescriptor

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: descriptor.iconName)
                .font(.body)
                .foregroundStyle(descriptor.color)
                .frame(width: 32, height: 32)
                .background(descriptor.color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(descriptor.name)
                .font(.body)
                .foregroundStyle(.primary)

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}
