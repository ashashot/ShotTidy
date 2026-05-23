//
//  ImportView.swift
//  ShotTidy
//
//  Импорт скриншотов из галереи и их AI-анализ.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var pendingImages: [(UIImage, String)] = []  // (image, filename)
    @State private var isProcessing = false
    @State private var progress: Double = 0
    @State private var currentStep = ""
    @State private var errorMessage: String?
    @State private var doneCount = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                if isProcessing {
                    processingView
                } else if pendingImages.isEmpty {
                    pickerPrompt
                } else {
                    previewGrid
                }
            }
            .padding()
            .navigationTitle("Импорт скриншотов")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") { dismiss() }
                }
                if !pendingImages.isEmpty && !isProcessing {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Анализировать") {
                            Task { await analyzeAll() }
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .alert("Ошибка", isPresented: .constant(errorMessage != nil)) {
                Button("OK") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - Views

    private var pickerPrompt: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "photo.stack")
                .font(.system(size: 64))
                .foregroundStyle(.blue.opacity(0.7))

            Text("Выберите скриншоты")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Выберите один или несколько скриншотов из галереи для анализа и добавления в каталог")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 20,
                matching: .screenshots
            ) {
                Label("Открыть галерею", systemImage: "photo.on.rectangle")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .onChange(of: selectedItems) { _, items in
                Task { await loadImages(from: items) }
            }

            Spacer()
        }
    }

    private var previewGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(pendingImages.count) скриншотов выбрано")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(pendingImages.indices, id: \.self) { i in
                        Image(uiImage: pendingImages[i].0)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }

            // Кнопка добавить ещё
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: 20,
                matching: .screenshots
            ) {
                Label("Изменить выбор", systemImage: "plus.circle")
                    .font(.subheadline)
            }
            .onChange(of: selectedItems) { _, items in
                Task { await loadImages(from: items) }
            }
        }
    }

    private var processingView: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .tint(.blue)

            VStack(spacing: 8) {
                Text(currentStep)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(doneCount) из \(pendingImages.count) проанализировано")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Logic

    private func loadImages(from items: [PhotosPickerItem]) async {
        pendingImages = []
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let filename = "\(UUID().uuidString).jpg"
                pendingImages.append((image, filename))
            }
        }
    }

    private func analyzeAll() async {
        guard !pendingImages.isEmpty else { return }
        isProcessing = true
        doneCount = 0
        progress = 0

        for (index, (image, filename)) in pendingImages.enumerated() {
            currentStep = "Анализ \(index + 1) из \(pendingImages.count)..."

            let screenshot = Screenshot()
            screenshot.originalFileName = filename
            screenshot.createdAt = Date()
            screenshot.analysisStatus = .analyzing

            // Сохраняем миниатюру
            let thumb = image.resized(toMaxDimension: 400)
            screenshot.thumbnailData = thumb.jpegData(compressionQuality: 0.8)

            modelContext.insert(screenshot)

            do {
                let analysis = try await OpenAIAPIClient.shared.analyzeScreenshot(image)
                screenshot.appName    = analysis.appName
                screenshot.category   = analysis.category
                screenshot.summary    = analysis.summary
                screenshot.mainIdea   = analysis.mainIdea
                screenshot.tags       = analysis.tags ?? []
                screenshot.analyzedAt = Date()
                screenshot.analysisStatus = .done
            } catch {
                screenshot.analysisStatus = .failed
                screenshot.errorMessage = error.localizedDescription
            }

            doneCount += 1
            progress = Double(doneCount) / Double(pendingImages.count)
        }

        isProcessing = false
        dismiss()
    }
}

