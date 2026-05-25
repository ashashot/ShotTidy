//
//  ScreenshotCard.swift
//  ShotTidy
//
//  Карточка скриншота в сетке каталога.
//

import SwiftUI

struct ScreenshotCard: View {
    let screenshot: Screenshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // MARK: Миниатюра
            thumbnailView
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(statusOverlay, alignment: .topTrailing)

            // MARK: Информация
            VStack(alignment: .leading, spacing: 3) {
                if let appName = screenshot.appName, !appName.isEmpty {
                    Text(appName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }

                if let mainIdea = screenshot.mainIdea, !mainIdea.isEmpty {
                    Text(mainIdea)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                CategoryBadge(category: screenshot.category)
                    .padding(.top, 2)
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Thumbnail

    @ViewBuilder
    private var thumbnailView: some View {
        if let data = screenshot.thumbnailData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Status Overlay

    @ViewBuilder
    private var statusOverlay: some View {
        switch screenshot.analysisStatus {
        case .analyzing:
            ProgressView()
                .scaleEffect(0.8)
                .padding(6)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .padding(6)

        case .failed:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
                .padding(6)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .padding(6)

        case .done, .pending:
            EmptyView()
        }
    }
}
