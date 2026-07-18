//
//  AnalysisLogView.swift
//  ShotTidy
//
//  Lets the user review what happened during screenshot analysis — useful when
//  AI detection seems off (falls back to manual entry, finds fewer items than
//  expected) and reproducing the issue live isn't practical.
//

import SwiftUI

struct AnalysisLogView: View {
    @State private var entries: [AnalysisLogEntry] = []
    @State private var showClearAlert = false

    var body: some View {
        List {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Analysis Logs Yet",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Logs appear here after you analyze screenshots.")
                )
            } else {
                ForEach(entries.reversed()) { entry in
                    NavigationLink {
                        AnalysisLogDetailView(entry: entry)
                    } label: {
                        AnalysisLogRow(entry: entry)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Analysis Log")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !entries.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            UIPasteboard.general.string = Self.exportText(entries)
                        } label: {
                            Label("Copy All", systemImage: "doc.on.doc")
                        }
                        Button(role: .destructive) {
                            showClearAlert = true
                        } label: {
                            Label("Clear Log", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert("Clear Analysis Log?", isPresented: $showClearAlert) {
            Button("Clear Log", role: .destructive) { clear() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes all analysis log entries stored on this device.")
        }
        .task { await load() }
        .refreshable { await load() }
    }

    private func load() async {
        entries = await AnalysisLogger.shared.entries()
    }

    private func clear() {
        Task {
            await AnalysisLogger.shared.clear()
            await load()
        }
    }

    private static func exportText(_ entries: [AnalysisLogEntry]) -> String {
        entries.map { entry in
            var lines = [
                entry.timestamp.formatted(date: .abbreviated, time: .standard),
                "\(entry.imageLabel) — \(entry.outcome.displayName)",
                entry.message,
            ]
            if let detail = entry.detail { lines.append(detail) }
            return lines.joined(separator: "\n")
        }.joined(separator: "\n\n---\n\n")
    }
}

// MARK: - Row

private struct AnalysisLogRow: View {
    let entry: AnalysisLogEntry

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: entry.outcome.iconName)
                .foregroundStyle(entry.outcome.tintColor)
                .font(.system(size: 16))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.imageLabel)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(entry.outcome.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(entry.timestamp, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Detail

private struct AnalysisLogDetailView: View {
    let entry: AnalysisLogEntry

    var body: some View {
        List {
            Section {
                LabeledContent("Screenshot", value: entry.imageLabel)
                LabeledContent("Outcome") {
                    Label(entry.outcome.displayName, systemImage: entry.outcome.iconName)
                        .foregroundStyle(entry.outcome.tintColor)
                }
                LabeledContent("Time", value: entry.timestamp.formatted(date: .abbreviated, time: .standard))
                if entry.outcome == .success || entry.outcome == .emptyItems {
                    LabeledContent("Items Found", value: "\(entry.itemCount)")
                }
            }

            Section("Message") {
                Text(entry.message)
                    .font(.subheadline)
            }

            if let detail = entry.detail {
                Section("Raw Response") {
                    Text(detail)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIPasteboard.general.string = fullText
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
            }
        }
    }

    private var fullText: String {
        var lines = [
            entry.timestamp.formatted(date: .abbreviated, time: .standard),
            "\(entry.imageLabel) — \(entry.outcome.displayName)",
            entry.message,
        ]
        if let detail = entry.detail { lines.append(detail) }
        return lines.joined(separator: "\n")
    }
}

// MARK: - Outcome presentation

extension AnalysisLogOutcome {
    var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .emptyItems: return "questionmark.circle.fill"
        case .refused: return "hand.raised.fill"
        case .emptyResponse: return "exclamationmark.circle.fill"
        case .decodingFailed: return "exclamationmark.triangle.fill"
        case .httpError: return "server.rack"
        case .quotaExceeded: return "gauge.with.needle.fill"
        case .networkError: return "wifi.slash"
        case .invalidImage: return "photo.badge.exclamationmark"
        }
    }

    var tintColor: Color {
        switch self {
        case .success: return .green
        case .emptyItems: return .orange
        default: return .red
        }
    }

    var displayName: String {
        switch self {
        case .success: return String(localized: "Success", bundle: AppLocale.bundle)
        case .emptyItems: return String(localized: "No Items Found", bundle: AppLocale.bundle)
        case .refused: return String(localized: "AI Refused", bundle: AppLocale.bundle)
        case .emptyResponse: return String(localized: "Empty Response", bundle: AppLocale.bundle)
        case .decodingFailed: return String(localized: "Parse Error", bundle: AppLocale.bundle)
        case .httpError: return String(localized: "Server Error", bundle: AppLocale.bundle)
        case .quotaExceeded: return String(localized: "Rate Limited", bundle: AppLocale.bundle)
        case .networkError: return String(localized: "Network Error", bundle: AppLocale.bundle)
        case .invalidImage: return String(localized: "Invalid Image", bundle: AppLocale.bundle)
        }
    }
}
