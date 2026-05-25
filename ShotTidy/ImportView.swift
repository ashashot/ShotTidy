//
//  ImportView.swift
//  ShotTidy
//
//  Screenshot import screen: gallery → AI analysis → confirmation.
//

import SwiftUI
import PhotosUI
import SwiftData

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel = ImportViewModel()
    // @State — stable storage for the sheet binding.
    // Set to true only AFTER analyzeImages() completes,
    // guaranteeing that draftItems are populated on ConfirmationView's first render.
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
            .navigationTitle("Import Screenshots")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        viewModel.fullReset()
                        dismiss()
                    }
                }
                if !viewModel.selectedImages.isEmpty && !viewModel.isAnalyzing {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Analyze") { startAnalysis() }
                            .fontWeight(.semibold)
                    }
                }
            }
            .alert("Analysis Error", isPresented: Binding(
                get: { viewModel.analysisError != nil },
                set: { if !$0 { viewModel.analysisError = nil } }
            )) {
                Button("OK") { viewModel.analysisError = nil }
            } message: {
                Text(viewModel.analysisError ?? "")
            }
            // $showConfirmation — stable @State binding.
            // dismiss() inside ConfirmationView correctly sets isPresented=false
            // via this binding; onDismiss is called AFTER the animation completes.
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

    // MARK: - Start analysis

    private func startAnalysis() {
        Task {
            await viewModel.analyzeImages()
            // Open ConfirmationView only HERE, after await —
            // at this point draftItems are guaranteed to be populated
            if !viewModel.draftItems.isEmpty {
                showConfirmation = true
            }
        }
    }

    // MARK: - Picker prompt view

    private var pickerPromptView: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "photo.badge.plus")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.blue.opacity(0.8))

                Text("Select Screenshots")
                    .font(.title2.bold())

                Text("AI will analyze the images\nand suggest adding data to the catalog")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            PhotosPicker(
                selection: $viewModel.selectedPickerItems,
                maxSelectionCount: 10,
                matching: .images
            ) {
                Label("Open Photos", systemImage: "photo.on.rectangle")
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

    // MARK: - Preview grid

    private var previewView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Preview of selected images
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

            // Bottom panel
            VStack(spacing: 12) {
                let count = viewModel.selectedImages.count
                Text("\(count) \(count == 1 ? "screenshot" : "screenshots") selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    // Change selection
                    PhotosPicker(
                        selection: $viewModel.selectedPickerItems,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        Text("Change")
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

                    // Analyze
                    Button {
                        startAnalysis()
                    } label: {
                        Label("Analyze", systemImage: "sparkles")
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

    // MARK: - Analyzing view

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
                    Text("Analyzing screenshots...")
                        .font(.headline)

                    Text("Image \(viewModel.progressCurrent) of \(viewModel.progressTotal)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }
}
