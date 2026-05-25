//
//  ImportView.swift
//  ShotTidy
//
//  Экран импорта скриншотов из галереи → AI-анализ → подтверждение.
//

import SwiftUI
import PhotosUI
import SwiftData

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ImportViewModel()
    // @State — стабильное хранилище для sheet-binding.
    // Устанавливается в true только ПОСЛЕ завершения await analyzeImages(),
    // гарантируя что draftItems уже заполнены при первом рендере ConfirmationView.
    @State private var showConfirmation = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isAnalyzing {
                    analyzingView
                } else if viewModel.selectedImages.isEmpty {
                    pickerPromptView
                } else {
                    previewView
                }
            }
            .navigationTitle("Импорт скриншотов")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        viewModel.fullReset()
                        dismiss()
                    }
                }
                if !viewModel.selectedImages.isEmpty && !viewModel.isAnalyzing {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Анализировать") { startAnalysis() }
                            .fontWeight(.semibold)
                    }
                }
            }
            .alert("Ошибка анализа", isPresented: Binding(
                get: { viewModel.analysisError != nil },
                set: { if !$0 { viewModel.analysisError = nil } }
            )) {
                Button("OK") { viewModel.analysisError = nil }
            } message: {
                Text(viewModel.analysisError ?? "")
            }
            // $showConfirmation — стабильный @State binding.
            // dismiss() внутри ConfirmationView корректно ставит isPresented=false
            // через этот binding, onDismiss вызывается ПОСЛЕ завершения анимации.
            .sheet(isPresented: $showConfirmation, onDismiss: {
                viewModel.resetAfterConfirmation()
            }) {
                ConfirmationView(viewModel: viewModel) {
                    showConfirmation = false
                    dismiss()
                }
            }
        }
        .onAppear {
            viewModel.modelContext = modelContext
        }
    }

    // MARK: - Запуск анализа

    private func startAnalysis() {
        Task {
            await viewModel.analyzeImages()
            // Открываем ConfirmationView только ЗДЕСЬ, после await —
            // в этой точке draftItems гарантированно заполнены
            if !viewModel.draftItems.isEmpty {
                showConfirmation = true
            }
        }
    }

    // MARK: - Prompt View

    private var pickerPromptView: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.blue.opacity(0.8))

                Text("Выберите скриншоты")
                    .font(.title2.bold())

                Text("AI проанализирует изображения\nи предложит добавить данные в каталог")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            PhotosPicker(
                selection: $viewModel.selectedPickerItems,
                maxSelectionCount: 10,
                matching: .images
            ) {
                Label("Открыть Фото", systemImage: "photo.on.rectangle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 32)
            .onChange(of: viewModel.selectedPickerItems) { _, _ in
                Task { await viewModel.loadSelectedImages() }
            }

            Spacer()
        }
    }

    // MARK: - Preview Grid

    private var previewView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Превью выбранных изображений
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 100), spacing: 4)],
                    spacing: 4
                ) {
                    ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { _, img in
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 110)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(4)
            }

            // Нижняя панель
            VStack(spacing: 12) {
                Text("\(viewModel.selectedImages.count) \(pluralImages(viewModel.selectedImages.count)) выбрано")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    // Изменить выбор
                    PhotosPicker(
                        selection: $viewModel.selectedPickerItems,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        Text("Изменить")
                            .font(.subheadline.weight(.medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemBackground))
                            .foregroundStyle(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .onChange(of: viewModel.selectedPickerItems) { _, _ in
                        Task { await viewModel.loadSelectedImages() }
                    }

                    // Анализировать
                    Button {
                        startAnalysis()
                    } label: {
                        Label("Анализировать", systemImage: "sparkles")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Analyzing View

    private var analyzingView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color(.systemFill), lineWidth: 4)
                        .frame(width: 72, height: 72)
                    Circle()
                        .trim(from: 0, to: viewModel.progressTotal > 0
                              ? CGFloat(viewModel.progressCurrent) / CGFloat(viewModel.progressTotal)
                              : 0)
                        .stroke(.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 72, height: 72)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.4), value: viewModel.progressCurrent)

                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(.blue)
                }

                VStack(spacing: 6) {
                    Text("Анализирую скриншоты...")
                        .font(.headline)

                    Text("Изображение \(viewModel.progressCurrent) из \(viewModel.progressTotal)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Helpers

    private func pluralImages(_ count: Int) -> String {
        switch count % 10 {
        case 1 where count % 100 != 11: return "скриншот"
        case 2...4 where count % 100 < 10 || count % 100 > 20: return "скриншота"
        default: return "скриншотов"
        }
    }
}
