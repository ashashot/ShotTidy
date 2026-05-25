//
//  DetailView.swift
//  ShotTidy
//
//  Детальный просмотр скриншота с результатами анализа.
//

import SwiftUI
import SwiftData

struct DetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let screenshot: Screenshot

    @State private var showDeleteAlert = false
    @State private var isReanalyzing = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: Изображение
                thumbnailSection

                // MARK: Контент
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    if screenshot.analysisStatus == .done {
                        analysisSection
                    } else {
                        statusSection
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }

                    Button {
                        Task { await reanalyze() }
                    } label: {
                        Label("Анализировать снова", systemImage: "arrow.clockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Удалить скриншот?", isPresented: $showDeleteAlert) {
            Button("Удалить", role: .destructive) { deleteAndDismiss() }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Запись будет удалена из каталога на всех устройствах.")
        }
        .alert("Ошибка", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var thumbnailSection: some View {
        if let data = screenshot.thumbnailData, let image = UIImage(data: data) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
        } else {
            Rectangle()
                .fill(Color(.secondarySystemBackground))
                .frame(height: 200)
                .overlay {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let appName = screenshot.appName {
                Text(appName)
                    .font(.title2)
                    .fontWeight(.bold)
            }

            HStack {
                CategoryBadge(category: screenshot.category)
                Spacer()
                if let date = screenshot.analyzedAt {
                    Text(date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var analysisSection: some View {
        VStack(alignment: .leading, spacing: 16) {

            // Главная идея
            if let idea = screenshot.mainIdea, !idea.isEmpty {
                InfoRow(icon: "lightbulb", title: "Идея", value: idea)
            }

            // Описание
            if let summary = screenshot.summary, !summary.isEmpty {
                InfoRow(icon: "text.alignleft", title: "Описание", value: summary)
            }

            // Теги
            if !screenshot.tags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Теги", systemImage: "tag")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)

                    FlowLayout(tags: screenshot.tags)
                }
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        HStack(spacing: 12) {
            switch screenshot.analysisStatus {
            case .analyzing:
                ProgressView()
                Text("Анализируем...")
                    .foregroundStyle(.secondary)

            case .failed:
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                VStack(alignment: .leading) {
                    Text("Ошибка анализа")
                        .fontWeight(.medium)
                    if let err = screenshot.errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

            case .pending:
                Image(systemName: "clock")
                    .foregroundStyle(.orange)
                Text("Ожидает анализа")
                    .foregroundStyle(.secondary)

            case .done:
                EmptyView()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Actions

    private func reanalyze() async {
        guard let data = screenshot.thumbnailData,
              let image = UIImage(data: data) else { return }

        screenshot.analysisStatus = .analyzing
        screenshot.errorMessage = nil

        do {
            let analysis = try await OpenAIAPIClient.shared.analyzeScreenshot(image)
            screenshot.appName   = analysis.appName
            screenshot.category  = analysis.category
            screenshot.summary   = analysis.summary
            screenshot.mainIdea  = analysis.mainIdea
            screenshot.tags      = analysis.tags ?? []
            screenshot.analyzedAt = Date()
            screenshot.analysisStatus = .done
        } catch {
            screenshot.analysisStatus = .failed
            screenshot.errorMessage = error.localizedDescription
            errorMessage = error.localizedDescription
        }
    }

    private func deleteAndDismiss() {
        modelContext.delete(screenshot)
        dismiss()
    }
}

// MARK: - Info Row

private struct InfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body)
        }
    }
}

// MARK: - Flow Layout (теги)

private struct FlowLayout: View {
    let tags: [String]

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
        .frame(height: 60)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(tags, id: \.self) { tag in
                TagChip(text: tag)
                    .alignmentGuide(.leading) { dimension in
                        if abs(width - dimension.width) > geometry.size.width {
                            width = 0
                            height -= dimension.height + 4
                        }
                        let result = width
                        if tag == tags.last {
                            width = 0
                        } else {
                            width -= dimension.width + 6
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if tag == tags.last { height = 0 }
                        return result
                    }
            }
        }
    }
}

private struct TagChip: View {
    let text: String

    var body: some View {
        Text("#\(text)")
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(.tertiarySystemBackground))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(Color(.separator), lineWidth: 0.5))
    }
}
