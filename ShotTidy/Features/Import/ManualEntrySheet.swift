//
//  ManualEntrySheet.swift
//  ShotTidy
//
//  Shown when AI analysis could not extract any data from a screenshot.
//  Lets the user pick a category and fill in the item manually.
//

import SwiftUI

struct ManualEntrySheet: View {
    var attachedImage: UIImage?
    var onSaved: () -> Void

    @Environment(\.dismiss)          private var dismiss
    @Environment(CategoryStore.self) private var categoryStore

    var body: some View {
        NavigationStack {
            List(categoryStore.allDescriptors) { descriptor in
                NavigationLink(value: descriptor) {
                    Label {
                        Text(descriptor.name)
                    } icon: {
                        Image(systemName: descriptor.iconName)
                            .foregroundStyle(descriptor.color)
                    }
                }
            }
            .navigationTitle("Add Manually")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .navigationDestination(for: CategoryDescriptor.self) { descriptor in
                ItemEditView(
                    descriptor: descriptor,
                    item: nil,
                    attachedImage: attachedImage,
                    onSaved: onSaved
                )
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                aiFailureNotice
            }
        }
    }

    private var aiFailureNotice: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles.slash")
                .foregroundStyle(.secondary)
            Text("AI couldn't extract data. Select a category to add manually.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .overlay(alignment: .bottom) { Divider() }
    }
}
