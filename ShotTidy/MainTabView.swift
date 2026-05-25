//
//  MainTabView.swift
//  ShotTidy
//
//  Root navigation: Catalog | Screenshots | Settings
//  On each foreground activation checks for items saved by the Share Extension
//  and silently imports them into SwiftData.
//

import SwiftUI
import SwiftData

struct MainTabView: View {

    @State private var showImport = false

    // Banner shown after a successful share-extension import
    @State private var importBanner: String? = nil

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            // MARK: Catalog
            CategoriesView(showImport: $showImport)
                .tabItem {
                    Label("Catalog", systemImage: "square.grid.2x2.fill")
                }

            // MARK: Screenshots
            ScreenshotsView(showImport: $showImport)
                .tabItem {
                    Label("Screenshots", systemImage: "photo.stack.fill")
                }

            // MARK: Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
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
        // Import on first appearance
        .onAppear {
            importPendingDraftsIfNeeded()
        }
        // Import every time the app comes back to the foreground
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                importPendingDraftsIfNeeded()
            }
        }
    }

    // MARK: - Pending import

    private func importPendingDraftsIfNeeded() {
        let pending = AppGroupManager.loadPendingDrafts()
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
