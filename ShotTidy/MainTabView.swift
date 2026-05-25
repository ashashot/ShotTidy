//
//  MainTabView.swift
//  ShotTidy
//
//  Корневая навигация: Каталог | Скриншоты | Настройки
//

import SwiftUI

struct MainTabView: View {
    @State private var showImport = false

    var body: some View {
        TabView {
            // MARK: Каталог
            CategoriesView(showImport: $showImport)
                .tabItem {
                    Label("Каталог", systemImage: "square.grid.2x2.fill")
                }

            // MARK: Скриншоты
            ScreenshotsView(showImport: $showImport)
                .tabItem {
                    Label("Скриншоты", systemImage: "photo.stack.fill")
                }

            // MARK: Настройки
            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
        }
        .sheet(isPresented: $showImport) {
            ImportView()
        }
    }
}
