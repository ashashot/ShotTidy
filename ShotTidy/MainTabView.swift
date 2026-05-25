//
//  MainTabView.swift
//  ShotTidy
//
//  Root navigation: Catalog | Screenshots | Settings
//

import SwiftUI

struct MainTabView: View {
    @State private var showImport = false

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
    }
}
