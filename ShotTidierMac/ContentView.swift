//
//  ContentView.swift
//  ShotTidierMac
//
//  Root NavigationSplitView: sidebar (categories) | item list | item detail.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    @State private var sidebarSelection: SidebarItem? = .category("shopping")
    @State private var selectedItem: CatalogItem?
    @State private var showImport = false

    @Environment(\.modelContext) private var modelContext
    @Environment(CategoryStore.self) private var categoryStore
    @Environment(MacCloudSyncMonitor.self) private var syncMonitor

    @Query private var userCategories: [UserCategory]

    var body: some View {
        NavigationSplitView {
            MacCategoriesSidebar(selection: $sidebarSelection, showImport: $showImport)
        } content: {
            contentView
        } detail: {
            detailView
        }
        .sheet(isPresented: $showImport) {
            NavigationStack {
                MacImportView()
                    .navigationTitle("Import Screenshots")
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                CloudSyncStatusButton()
            }
        }
        .onAppear {
            categoryStore.configure(context: modelContext)
        }
        .onChange(of: userCategories.count) { _, _ in
            categoryStore.reload()
        }
    }

    // MARK: - Content column

    @ViewBuilder
    private var contentView: some View {
        switch sidebarSelection {
        case .category(let key):
            let descriptor = categoryStore.descriptor(forKey: key)
            MacCategoryItemsView(descriptor: descriptor, selectedItem: $selectedItem)
        case .screenshots:
            MacScreenshotsView()
        case nil:
            Text("Select a category")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Detail column

    @ViewBuilder
    private var detailView: some View {
        if let item = selectedItem {
            MacItemDetailView(item: item)
        } else {
            VStack(spacing: 16) {
                Image(systemName: "sidebar.right")
                    .font(.system(size: 40))
                    .foregroundStyle(.quaternary)
                Text("Select an item to view details")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - CloudSyncStatusButton

/// Toolbar indicator for iCloud sync state. Factored into its own `View` so it
/// invalidates only when the sync state changes — and to avoid `AnyView` type
/// erasure in the toolbar.
private struct CloudSyncStatusButton: View {

    @Environment(MacCloudSyncMonitor.self) private var syncMonitor
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        if syncMonitor.isSyncing {
            ProgressView()
                .controlSize(.small)
                .help("Syncing with iCloud…")
        } else {
            Button {
                syncMonitor.triggerSync(context: modelContext)
            } label: {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
            }
            .buttonStyle(.plain)
            .help(helpText)
        }
    }

    private var iconName: String {
        switch syncMonitor.state {
        case .idle:    return "checkmark.icloud"
        case .syncing: return "icloud"
        case .error:   return "exclamationmark.icloud"
        }
    }

    private var iconColor: Color {
        switch syncMonitor.state {
        case .idle:    return .secondary
        case .syncing: return .accentColor
        case .error:   return .red
        }
    }

    private var helpText: String {
        switch syncMonitor.state {
        case .idle:           return "iCloud sync active — click to sync now"
        case .syncing:        return "Syncing with iCloud…"
        case .error(let msg): return "iCloud error: \(msg)"
        }
    }
}
