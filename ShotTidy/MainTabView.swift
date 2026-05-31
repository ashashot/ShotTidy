//
//  MainTabView.swift
//  ShotTidy
//
//  Root navigation: Catalog | Screenshots | Settings
//  On each foreground activation checks for items saved by the Share Extension
//  and silently imports them into SwiftData.
//
//  Deep link URL scheme (shottidy://):
//    shottidy://            → Catalog tab
//    shottidy://catalog     → Catalog tab
//    shottidy://import      → open Import sheet
//    shottidy://screenshots → Screenshots tab
//    shottidy://settings    → Settings tab

import SwiftUI
import SwiftData
import Combine

// MARK: - Deep Link

enum DeepLink {
    case catalog
    case screenshots
    case settings
    case openImport

    /// Parse a `shottidy://` URL into a DeepLink action.
    /// Returns `nil` for unrecognised paths (silently ignored).
    init?(url: URL) {
        guard url.scheme?.lowercased() == "shottidy" else { return nil }
        switch url.host?.lowercased() {
        case nil, "", "catalog": self = .catalog
        case "import":           self = .openImport
        case "screenshots":      self = .screenshots
        case "settings":         self = .settings
        default:                 return nil
        }
    }
}

// MARK: - Tab

enum AppTab: Hashable {
    case catalog, screenshots, settings
}

// MARK: - View

struct MainTabView: View {

    @State private var selectedTab: AppTab = .catalog
    @State private var showImport = false

    // Banner shown after a successful share-extension import
    @State private var importBanner: String? = nil

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    /// Snapshot of the catalog count — used to detect when items are added/removed
    /// so we can refresh the App Group index for the Share Extension.
    @Query private var allCatalogItems: [CatalogItem]

    var body: some View {
        TabView(selection: $selectedTab) {
            // MARK: Catalog
            CategoriesView(showImport: $showImport)
                .tabItem {
                    Label("Catalog", systemImage: "square.grid.2x2.fill")
                }
                .tag(AppTab.catalog)

            // MARK: Screenshots
            ScreenshotsView(showImport: $showImport)
                .tabItem {
                    Label("Screenshots", systemImage: "photo.stack.fill")
                }
                .tag(AppTab.screenshots)

            // MARK: Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(AppTab.settings)
        }
        .sheet(isPresented: $showImport) {
            ImportView()
        }
        // Success banner (appears above the tab bar)
        .overlay(alignment: .top) {
            if let text = importBanner {
                ImportBanner(text: text)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(999)
                    .padding(.top, 8)
            }
        }
        .animation(.spring(duration: 0.35), value: importBanner)
        // Import on first appearance + sync catalog index for Share Extension
        .onAppear {
            syncCatalogIndex()
            importPendingDraftsIfNeeded()
        }
        // Re-sync when items are added / removed in any in-app flow
        .onChange(of: allCatalogItems.count) { _, _ in
            syncCatalogIndex()
        }
        // Sync when Import sheet closes (covers newly added in-app items)
        .onChange(of: showImport) { _, isShowing in
            if !isShowing { syncCatalogIndex() }
        }
        // Import + sync every time the app comes back to the foreground
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                syncCatalogIndex()
                importPendingDraftsIfNeeded()
            }
        }
        // MARK: Deep link handling
        .onOpenURL { url in
            guard let link = DeepLink(url: url) else { return }
            handleDeepLink(link)
        }
    }

    // MARK: - Deep Link Router

    private func handleDeepLink(_ link: DeepLink) {
        switch link {
        case .catalog:
            selectedTab = .catalog
        case .screenshots:
            selectedTab = .screenshots
        case .settings:
            selectedTab = .settings
        case .openImport:
            selectedTab = .catalog
            // Small delay so the tab switch completes before the sheet opens
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                showImport = true
            }
        }
    }

    // MARK: - Catalog index sync (for Share Extension duplicate detection)

    /// Writes a lightweight JSON snapshot of the entire catalog to the App Group container.
    /// The Share Extension reads this file to detect duplicates without SwiftData access.
    private func syncCatalogIndex() {
        let entries = allCatalogItems.map {
            CatalogIndexEntry(
                categoryKey: $0.categoryRaw,
                title: $0.title,
                subtitle: $0.subtitle,
                link: $0.link
            )
        }
        AppGroupManager.saveCatalogIndex(entries)
    }

    // MARK: - Pending import

    private func importPendingDraftsIfNeeded() {
        print("[MainApp] App Group container: \(AppGroupManager.containerURL?.path ?? "nil")")
        let pending = AppGroupManager.loadPendingDrafts()
        print("[MainApp] Pending drafts count: \(pending.count)")
        guard !pending.isEmpty else { return }

        var imported = 0
        for draft in pending {
            guard let category = ItemCategory(rawValue: draft.categoryKey) else { continue }
            let item = CatalogItem(
                category: category,
                title: draft.title,
                subtitle: draft.subtitle.isEmpty ? nil : draft.subtitle,
                link: draft.link.isEmpty ? nil : draft.link,
                extra1: draft.extra1.isEmpty ? nil : draft.extra1,
                extra2: draft.extra2.isEmpty ? nil : draft.extra2,
                notes: draft.notes.isEmpty ? nil : draft.notes
            )
            modelContext.insert(item)
            imported += 1
        }

        guard imported > 0 else {
            AppGroupManager.clearPendingDrafts()
            return
        }

        try? modelContext.save()
        AppGroupManager.clearPendingDrafts()
        syncCatalogIndex()  // refresh index so next Share Extension session sees these items

        let word = imported == 1 ? "item" : "items"
        importBanner = "✅ \(imported) \(word) added from Share"

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            importBanner = nil
        }
    }
}

// MARK: - Import Banner

private struct ImportBanner: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background(Color.green, in: Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }
}
