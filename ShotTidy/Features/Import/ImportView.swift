//
//  ImportView.swift
//  ShotTidy
//
//  Screenshot import screen: gallery → AI analysis → confirmation.
//  Free users are limited to 5 screenshots per month.
//  A paywall sheet is shown when the limit is reached.
//

import SwiftUI
import PhotosUI
import SwiftData

struct ImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss
    @Environment(SubscriptionManager.self) private var subManager
    @Environment(UsageManager.self)        private var usageManager
    @Environment(CategoryStore.self)       private var categoryStore

    @State private var viewModel = ImportViewModel()
    // Set to true only AFTER analyzeImages() completes,
    // guaranteeing that draftItems are populated on ConfirmationView's first render.
    @State private var showConfirmation  = false
    @State private var showPaywall       = false
    @State private var showManualEntry   = false
    @State private var manualEntryImage: UIImage? = nil

    // MARK: - Analysis animation state

    /// Brief "success" screen shown between analysis finishing and ConfirmationView opening.
    @State private var showCompletion    = false
    @State private var completionCount   = 0
    /// Toggled to trigger the checkmark bounce on the completion screen.
    @State private var bounceCheckmark   = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isAnalyzing {
                    analyzingView
                        .transition(.opacity)
                } else if showCompletion {
                    completionView
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                } else if viewModel.selectedImages.isEmpty {
                    pickerPromptView
                } else {
                    previewView
                }
            }
            .animation(.easeInOut(duration: 0.35), value: viewModel.isAnalyzing)
            .animation(.spring(response: 0.45, dampingFraction: 0.7), value: showCompletion)
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
            .sheet(isPresented: $showManualEntry) {
                ManualEntrySheet(
                    attachedImage: manualEntryImage,
                    onSaved: {
                        showManualEntry = false
                        dismiss()
                    }
                )
            }
            .sheet(isPresented: $showConfirmation, onDismiss: {
                viewModel.resetAfterConfirmation()
            }) {
                ConfirmationView(viewModel: viewModel) {
                    showConfirmation = false
                    dismiss()
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
        .onAppear {
            viewModel.modelContext = modelContext
        }
    }

    // MARK: - Start analysis (with limit check)

    private func startAnalysis() {
        let count = viewModel.selectedImages.count
        guard usageManager.canAnalyzeScreenshots(count: count, isPro: subManager.isProActive) else {
            showPaywall = true
            return
        }

        // Custom categories let the AI match (and, for Pro, suggest) user categories.
        let customPayload = categoryStore.customDescriptors.map {
            CategoryPromptInfo(key: $0.key, name: $0.name, hint: $0.aiHint ?? "")
        }

        Task {
            await viewModel.analyzeImages(
                customCategories: customPayload,
                allowNewCategory: subManager.isProActive
            )
            // Open ConfirmationView only after await — draftItems are populated at this point
            if !viewModel.draftItems.isEmpty {
                // Consume quota for the screenshots that were submitted
                usageManager.consumeScreenshots(count: count)

                // Show a brief "success" screen before handing off to ConfirmationView
                completionCount = viewModel.draftItems.count
                showCompletion  = true
                try? await Task.sleep(for: .milliseconds(750))

                showConfirmation = true
                showCompletion   = false
            } else if viewModel.quotaExceededMessage != nil {
                // Server rejected every screenshot for quota/rate-limit reasons — the
                // client-side pre-check above can be stale, so this can still happen.
                // Route to the paywall instead of the "add manually" fallback, which
                // would otherwise hide the real reason from the user.
                viewModel.resetAfterConfirmation()
                viewModel.quotaExceededMessage = nil
                showPaywall = true
            } else {
                // AI found nothing (or errored) — clean up and offer manual entry
                viewModel.resetAfterConfirmation()
                viewModel.analysisError = nil
                manualEntryImage = viewModel.selectedImages.first
                showManualEntry = true
            }
        }
    }

    // MARK: - Remaining quota info

    /// Whether the selected batch exceeds the free limit.
    private var isOverLimit: Bool {
        !subManager.isProActive &&
        !usageManager.canAnalyzeScreenshots(count: viewModel.selectedImages.count, isPro: false)
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

            // Quota badge (free users only)
            if !subManager.isProActive {
                quotaBadge
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
            VStack(spacing: 10) {
                let count = viewModel.selectedImages.count
                Text("\(count) screenshot(s) selected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Over-limit warning
                if isOverLimit {
                    overLimitBanner
                }

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

                    // Analyze / Upgrade button
                    if isOverLimit {
                        Button {
                            showPaywall = true
                        } label: {
                            Label("Upgrade", systemImage: "sparkles")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.purple)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    } else {
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
                TimelineView(.animation) { timeline in
                    let now = timeline.date.timeIntervalSinceReferenceDate

                    ZStack {
                        // Radar-style pulsing halos behind the progress ring
                        ForEach(0..<2, id: \.self) { i in
                            let phase = Self.haloPhase(at: now, index: i)
                            Circle()
                                .fill(Color.blue.opacity(0.10))
                                .frame(width: 88, height: 88)
                                .scaleEffect(0.85 + phase * 0.55)
                                .opacity(0.6 * (1 - phase))
                        }

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
                            .symbolEffect(.pulse)
                    }
                }
                .frame(width: 88, height: 88)

                VStack(spacing: 6) {
                    Text("Analyzing screenshots...")
                        .font(.headline)

                    HStack(spacing: 4) {
                        Text("Image")
                        Text("\(viewModel.progressCurrent)")
                            .contentTransition(.numericText())
                            .animation(.snappy, value: viewModel.progressCurrent)
                        Text("of \(viewModel.progressTotal)")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    /// Computes a repeating 0...1 "pulse" phase for radar halo `index`, looping every 1.8s
    /// with a per-index stagger so the rings expand out of sync.
    static func haloPhase(at time: TimeInterval, index: Int) -> Double {
        let period: Double = 1.8
        let delay = Double(index) * 0.7
        let t = (time - delay).truncatingRemainder(dividingBy: period)
        return (t < 0 ? t + period : t) / period
    }

    // MARK: - Completion view

    /// Brief "success" screen shown after analysis finishes and before ConfirmationView opens.
    private var completionView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.12))
                        .frame(width: 72, height: 72)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.green)
                        .symbolEffect(.bounce, value: bounceCheckmark)
                }
                .onAppear { bounceCheckmark.toggle() }

                VStack(spacing: 6) {
                    Text("Analysis Complete")
                        .font(.headline)

                    Text("\(completionCount) item(s) found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    // MARK: - Subviews

    /// Pill showing remaining free screenshots.
    private var quotaBadge: some View {
        let remaining = usageManager.remainingScreenshots(isPro: false)
        let total     = UsageManager.freeScreenshotsPerPeriod
        return HStack(spacing: 6) {
            Image(systemName: remaining > 0 ? "photo.stack" : "exclamationmark.circle.fill")
                .font(.caption.weight(.semibold))
            if remaining > 0 {
                Text("\(remaining) of \(total) free screenshots remaining (30-day period)")
                    .font(.caption.weight(.medium))
            } else {
                Text("Free limit reached — upgrade for unlimited access")
                    .font(.caption.weight(.medium))
            }
        }
        .foregroundStyle(remaining > 0 ? Color.secondary : Color.red)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            (remaining > 0 ? Color(.systemFill) : Color.red.opacity(0.10))
        )
        .clipShape(Capsule())
    }

    /// Warning banner shown in previewView when selection exceeds quota.
    private var overLimitBanner: some View {
        let remaining = usageManager.remainingScreenshots(isPro: false)
        return HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.caption)
            Text(remaining == 0
                 ? "Free limit reached. Upgrade to analyze more screenshots."
                 : "Only \(remaining) screenshot(s) left this month.")
                .font(.caption.weight(.medium))
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(Color.orange.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.orange.opacity(0.25), lineWidth: 1)
        )
    }
}
