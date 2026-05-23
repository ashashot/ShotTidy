//
//  CatalogView.swift
//  ShotTidy
//

import SwiftUI
import SwiftData
import UIKit

struct CatalogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Screenshot.createdAt, order: .reverse) private var screenshots: [Screenshot]

    @State private var searchText        = ""
    @State private var selectedCategory: String? = nil
    @State private var showImport        = false
    @State private var selectedScreenshot: Screenshot? = nil
    @State private var debugMessage      = ""

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 12)]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if screenshots.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 0) {
                        categoryFilterBar
                        screenshotsGrid
                    }
                }
            }
            .navigationTitle("ShotTidy")
            .searchable(text: $searchText, prompt: "Поиск по скриншотам...")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showImport = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
                // Кнопка ручной проверки — для отладки
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        processPendingImages()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            // Отладочный баннер
            .safeAreaInset(edge: .bottom) {
                if !debugMessage.isEmpty {
                    Text(debugMessage)
                        .font(.caption)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.15))
                        .onTapGesture { debugMessage = "" }
                }
            }
            .sheet(isPresented: $showImport) { ImportView() }
            .sheet(item: $selectedScreenshot) { shot in
                NavigationStack { DetailView(screenshot: shot) }
            }
            // При появлении экрана
            .onAppear {
                processPendingImages()
            }
            // При каждом выходе приложения на передний план
            .onReceive(
                NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            ) { _ in
                processPendingImages()
            }
        }
    }

    // MARK: - Pending images processor

    private func processPendingImages() {
        let urls = AppGroupManager.pendingImageURLs()

        guard !urls.isEmpty else {
            let dir = AppGroupManager.pendingImagesDir?.path ?? "nil"
            debugMessage = "Файлов нет · \(dir)"
            return
        }

        debugMessage = "Найдено \(urls.count) файл(ов)…"

        for url in urls {
            // Сначала удаляем файл — чтобы не обработать дважды
            guard let data = try? Data(contentsOf: url) else {
                AppGroupManager.deletePendingImage(at: url)
                debugMessage = "Не удалось прочитать файл"
                continue
            }
            AppGroupManager.deletePendingImage(at: url)

            guard let image = UIImage(data: data) else {
                debugMessage = "Не удалось создать UIImage"
                continue
            }

            // Создаём запись
            let screenshot = Screenshot()
            screenshot.originalFileName = url.lastPathComponent
            screenshot.createdAt = Date()
            screenshot.analysisStatus = .analyzing

            let thumb = image.resized(toMaxDimension: 400)
            screenshot.thumbnailData = thumb.jpegData(compressionQuality: 0.8)

            modelContext.insert(screenshot)

            // Сохраняем сразу — иначе запись может не появиться в @Query
            try? modelContext.save()

            debugMessage = "Скриншот добавлен, анализирую…"

            Task {
                do {
                    let analysis = try await OpenAIAPIClient.shared.analyzeScreenshot(image)
                    screenshot.appName    = analysis.appName
                    screenshot.category   = analysis.category
                    screenshot.summary    = analysis.summary
                    screenshot.mainIdea   = analysis.mainIdea
                    screenshot.tags       = analysis.tags ?? []
                    screenshot.analyzedAt = Date()
                    screenshot.analysisStatus = .done
                    try? modelContext.save()
                    debugMessage = "✅ \(analysis.appName ?? "Готово")"
                } catch {
                    screenshot.analysisStatus = .failed
                    screenshot.errorMessage = error.localizedDescription
                    try? modelContext.save()
                    debugMessage = "❌ \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - Filtered list

    private var filtered: [Screenshot] {
        screenshots.filter { shot in
            if let cat = selectedCategory, shot.category != cat { return false }
            if !searchText.isEmpty {
                let q = searchText.lowercased()
                let inApp     = shot.appName?.lowercased().contains(q) ?? false
                let inSummary = shot.summary?.lowercased().contains(q) ?? false
                let inIdea    = shot.mainIdea?.lowercased().contains(q) ?? false
                let inTags    = shot.tags.contains { $0.lowercased().contains(q) }
                if !inApp && !inSummary && !inIdea && !inTags { return false }
            }
            return true
        }
    }

    // MARK: - Category Filter Bar

    private var categoryFilterBar: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    FilterChip(label: "Все", isSelected: selectedCategory == nil) {
                        selectedCategory = nil
                    }
                    ForEach(ScreenshotCategory.allCases, id: \.rawValue) { cat in
                        FilterChip(
                            label: cat.rawValue,
                            icon: cat.icon,
                            isSelected: selectedCategory == cat.rawValue
                        ) {
                            selectedCategory = selectedCategory == cat.rawValue ? nil : cat.rawValue
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(Color(.systemBackground))
            Divider()
        }
    }

    // MARK: - Grid

    private var screenshotsGrid: some View {
        ScrollView {
            if filtered.isEmpty {
                noResultsState.padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(filtered) { shot in
                        ScreenshotCard(screenshot: shot)
                            .contentShape(Rectangle())
                            .onTapGesture { selectedScreenshot = shot }
                    }
                }
                .padding()
            }
        }
    }

    // MARK: - Empty States

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.stack")
                .font(.system(size: 72))
                .foregroundStyle(.blue.opacity(0.6))
            Text("Каталог пуст")
                .font(.title2).fontWeight(.semibold)
            Text("Нажмите **+** чтобы выбрать скриншоты,\nили поделитесь ими из Фото")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            Button {
                showImport = true
            } label: {
                Label("Добавить скриншоты", systemImage: "plus")
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(.blue).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            // Отладка App Group
            if !debugMessage.isEmpty {
                Text(debugMessage)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }
        }
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass").font(.largeTitle).foregroundStyle(.tertiary)
            Text("Ничего не найдено").foregroundStyle(.secondary)
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let label: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon { Image(systemName: icon).font(.caption) }
                Text(label).font(.subheadline)
            }
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background(isSelected ? Color.blue : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .clipShape(Capsule())
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    CatalogView()
        .modelContainer(for: Screenshot.self, inMemory: true)
}
