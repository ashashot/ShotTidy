//
//  QuickImportWidget.swift
//  ShotTidyWidget
//
//  One-tap "Import Screenshot" button (Small only).
//  Opens the Import screen directly via the shottidy://import deep link.
//

import WidgetKit
import SwiftUI

// MARK: - Entry

struct QuickImportEntry: TimelineEntry {
    let date: Date
    let totalItems: Int
}

// MARK: - Provider

struct QuickImportProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickImportEntry {
        QuickImportEntry(date: Date(), totalItems: 24)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickImportEntry) -> Void) {
        completion(QuickImportEntry(date: Date(), totalItems: WidgetDataReader.readSnapshot().items.count))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickImportEntry>) -> Void) {
        let count   = WidgetDataReader.readSnapshot().items.count
        let entry   = QuickImportEntry(date: Date(), totalItems: count)
        let refresh = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }
}

// MARK: - Widget

struct QuickImportWidget: Widget {
    let kind = "QuickImportWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickImportProvider()) { entry in
            QuickImportWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color(.systemBackground) }
        }
        .configurationDisplayName("Quick Import")
        .description("Tap to add a new screenshot to your catalog.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - View

struct QuickImportWidgetView: View {
    let entry: QuickImportEntry

    var body: some View {
        Link(destination: URL(string: "shottidy://import")!) {
            VStack(spacing: 7) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 21, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                }

                Text("Import")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("\(entry.totalItems) items")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
