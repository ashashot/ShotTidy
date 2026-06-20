//
//  MacImportView.swift
//  ShotTidierMac
//
//  Import window: select images via NSOpenPanel → AI analysis → confirmation.
//

import SwiftUI
import AppKit
import SwiftData
import UniformTypeIdentifiers

struct MacImportView: View {

    @State private var viewModel = MacImportViewModel()
    @State private var showConfirmation = false
    @State private var showCompletion = false
    @State private var completionCount = 0

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(CategoryStore.self) private var categoryStore

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isAnalyzing {
                analyzingView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            } else if showCompletion {
                completionView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            } else if viewModel.selectedImages.isEmpty {
                dropZoneView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                previewView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isAnalyzing)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showCompletion)
        .frame(minWidth: 600, minHeight: 400)
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
                        .keyboardShortcut(.return, modifiers: .command)
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
        .sheet(isPresented: $showConfirmation, onDismiss: {
            viewModel.resetAfterConfirmation()
        }) {
            MacConfirmationView(viewModel: viewModel) {
                showConfirmation = false
                dismiss()
            }
        }
        .onAppear {
            viewModel.modelContext = modelContext
        }
    }

    // MARK: - Drop zone

    private var dropZoneView: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(.blue.opacity(0.7))

            VStack(spacing: 8) {
                Text("Select Screenshots")
                    .font(.title2.bold())
                Text("AI will analyze your images and extract structured data\ninto your catalog automatically")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: openImagePanel) {
                Label("Open Images…", systemImage: "folder.badge.plus")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .keyboardShortcut("o", modifiers: .command)
        }
        .padding(48)
        .onDrop(of: [.image, .fileURL], isTargeted: nil, perform: handleDrop)
    }

    // MARK: - Preview grid

    private var previewView: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 140), spacing: 8)],
                    spacing: 8
                ) {
                    ForEach(Array(viewModel.selectedImages.enumerated()), id: \.offset) { index, img in
                        ZStack(alignment: .topTrailing) {
                            Image(nsImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 130)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))

                            Button {
                                viewModel.selectedImages.remove(at: index)
                                if viewModel.selectedURLs.indices.contains(index) {
                                    viewModel.selectedURLs.remove(at: index)
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .symbolRenderingMode(.multicolor)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                            .padding(6)
                        }
                    }

                    Button(action: openImagePanel) {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle")
                                .font(.title)
                                .foregroundStyle(.secondary)
                            Text("Add more")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 130)
                        .background(.quaternary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }

            Divider()

            HStack(spacing: 12) {
                Text("\(viewModel.selectedImages.count) image\(viewModel.selectedImages.count == 1 ? "" : "s") selected")
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Change Selection", action: openImagePanel)
                Button("Analyze") { startAnalysis() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return, modifiers: .command)
            }
            .padding()
        }
    }

    // MARK: - Analyzing view

    private var analyzingView: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                    .frame(width: 80, height: 80)
                Circle()
                    .trim(
                        from: 0,
                        to: viewModel.progressTotal > 0
                            ? CGFloat(viewModel.progressCurrent) / CGFloat(viewModel.progressTotal)
                            : 0
                    )
                    .stroke(.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.4), value: viewModel.progressCurrent)

                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundStyle(.blue)
                    .symbolEffect(.pulse)
            }

            VStack(spacing: 6) {
                Text("Analyzing screenshots…")
                    .font(.title3.bold())
                Text("Image \(viewModel.progressCurrent) of \(viewModel.progressTotal)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: viewModel.progressCurrent)
            }
        }
    }

    // MARK: - Completion view

    private var completionView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            VStack(spacing: 6) {
                Text("Analysis Complete")
                    .font(.title3.bold())
                Text("\(completionCount) item\(completionCount == 1 ? "" : "s") found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Actions

    private func openImagePanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image, .jpeg, .png, .gif, .heic]
        panel.title = "Select Screenshots"
        panel.prompt = "Select"

        panel.begin { response in
            guard response == .OK else { return }
            let newImages = panel.urls.compactMap { NSImage(contentsOf: $0) }
            let newURLs = panel.urls

            if viewModel.selectedImages.isEmpty {
                viewModel.selectedImages = newImages
                viewModel.selectedURLs = newURLs
            } else {
                viewModel.selectedImages.append(contentsOf: newImages)
                viewModel.selectedURLs.append(contentsOf: newURLs)
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var loaded = false
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.image") {
                provider.loadItem(forTypeIdentifier: "public.image", options: nil) { item, _ in
                    DispatchQueue.main.async {
                        if let url = item as? URL, let img = NSImage(contentsOf: url) {
                            viewModel.selectedImages.append(img)
                            viewModel.selectedURLs.append(url)
                        } else if let data = item as? Data, let img = NSImage(data: data) {
                            viewModel.selectedImages.append(img)
                        }
                    }
                }
                loaded = true
            }
        }
        return loaded
    }

    private func startAnalysis() {
        let customPayload = categoryStore.customDescriptors.map {
            CategoryPromptInfo(key: $0.key, name: $0.name, hint: $0.aiHint ?? "")
        }

        Task {
            await viewModel.analyzeImages(customCategories: customPayload)
            if !viewModel.draftItems.isEmpty {
                completionCount = viewModel.draftItems.count
                showCompletion = true
                try? await Task.sleep(for: .milliseconds(700))
                showConfirmation = true
                showCompletion = false
            } else {
                viewModel.resetAfterConfirmation()
            }
        }
    }
}
