//
//  ImportViewModel.swift
//  ShotTidy
//
//  ViewModel для импорта и AI-анализа скриншотов.
//

import SwiftUI
import PhotosUI
import SwiftData

@Observable
@MainActor
final class ImportViewModel {

    // MARK: - Фото
    var selectedPickerItems: [PhotosPickerItem] = []
    var selectedImages: [UIImage] = []

    // MARK: - Состояние анализа
    var isAnalyzing = false
    var analysisError: String? = nil
    var progressCurrent = 0
    var progressTotal = 0
    /// Предупреждения (отказы отдельных скриншотов, не фатальные)
    var warnings: [String] = []

    // MARK: - Черновики (результат анализа, до подтверждения)
    var draftItems: [DraftItem] = []

    // MARK: - Контекст SwiftData (инжектируется из View)
    var modelContext: ModelContext?

    // MARK: - Загрузка изображений из PhotosPicker

    func loadSelectedImages() async {
        selectedImages = []
        for item in selectedPickerItems {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImages.append(image)
            }
        }
    }

    // MARK: - Анализ

    func analyzeImages() async {
        guard !selectedImages.isEmpty else { return }
        guard let ctx = modelContext else { return }

        isAnalyzing = true
        analysisError = nil
        warnings = []
        draftItems = []
        progressCurrent = 0
        progressTotal = selectedImages.count

        for (index, image) in selectedImages.enumerated() {
            progressCurrent = index + 1

            // Сохраняем скриншот как резервную копию
            let screenshot = Screenshot()
            screenshot.originalFileName = "screenshot_\(index + 1).jpg"
            screenshot.createdAt = Date()
            screenshot.analysisStatus = .analyzing

            let thumb = image.resized(toMaxDimension: 500)
            screenshot.thumbnailData = thumb.jpegData(compressionQuality: 0.8)

            ctx.insert(screenshot)
            try? ctx.save()

            do {
                let extracted = try await OpenAIAPIClient.shared.analyzeScreenshot(
                    image,
                    screenshotId: screenshot.id
                )

                draftItems.append(contentsOf: extracted)
                screenshot.analysisStatus = .done
                screenshot.analyzedAt = Date()
                screenshot.extractedItemsCount = extracted.count
            } catch let err as OpenAIError {
                screenshot.analysisStatus = .failed
                screenshot.errorMessage = err.localizedDescription

                switch err {
                case .refused, .emptyResponse:
                    // Отказ — не фатально, просто пропускаем этот скриншот
                    let name = screenshot.originalFileName ?? "скриншот \(index + 1)"
                    warnings.append("\(name): \(err.localizedDescription)")
                case .noAPIKey:
                    // Фатально — прерываем весь анализ
                    analysisError = err.localizedDescription
                    isAnalyzing = false
                    try? ctx.save()
                    return
                default:
                    // Сетевые/HTTP ошибки — показываем только если ничего не извлекли
                    if draftItems.isEmpty && index == selectedImages.count - 1 {
                        analysisError = err.localizedDescription
                    }
                }
            } catch {
                screenshot.analysisStatus = .failed
                screenshot.errorMessage = error.localizedDescription
                if draftItems.isEmpty && index == selectedImages.count - 1 {
                    analysisError = error.localizedDescription
                }
            }

            try? ctx.save()
        }

        isAnalyzing = false
        // showConfirmation убран из ViewModel — управляется @State в ImportView
        // чтобы sheet открывался ровно ПОСЛЕ завершения async-функции, без race-condition
    }

    // MARK: - Сохранение подтверждённых элементов

    func saveSelectedDrafts() {
        guard let ctx = modelContext else { return }
        let toSave = draftItems.filter { $0.isSelected && $0.isValid }
        for draft in toSave {
            ctx.insert(draft.toCatalogItem())
        }
        try? ctx.save()
        resetAfterConfirmation()
    }

    // MARK: - Сброс

    func resetAfterConfirmation() {
        draftItems = []
        warnings = []
    }

    func fullReset() {
        selectedPickerItems = []
        selectedImages = []
        draftItems = []
        isAnalyzing = false
        analysisError = nil
        warnings = []
        progressCurrent = 0
        progressTotal = 0
    }
}
