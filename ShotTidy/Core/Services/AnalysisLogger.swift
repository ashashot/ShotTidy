//
//  AnalysisLogger.swift
//  ShotTidy
//
//  Persists screenshot-analysis outcomes to a local file so the user can review
//  what happened after the fact — the "AI Detection" step can fail in ways that
//  never surface a hard error (e.g. HTTP 200 with an empty items array), so
//  ImportViewModel's transient in-memory warnings aren't enough to diagnose a
//  report of "detection stopped working, it just asks me to fill in manually".
//

import Foundation

// MARK: - AnalysisLogOutcome

enum AnalysisLogOutcome: String, Codable {
    case success
    /// HTTP 200, valid JSON, but the model returned zero items — no error is
    /// thrown for this case elsewhere, so without logging it it's invisible.
    case emptyItems
    case refused
    case emptyResponse
    case decodingFailed
    case httpError
    case quotaExceeded
    case networkError
    case invalidImage
}

// MARK: - AnalysisLogEntry

struct AnalysisLogEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var timestamp: Date = Date()
    var imageLabel: String
    var outcome: AnalysisLogOutcome
    var itemCount: Int = 0
    var message: String
    /// Raw model response snippet, truncated — the most useful clue when the
    /// model silently returned nothing or malformed JSON.
    var detail: String? = nil
}

// MARK: - AnalysisLogger

actor AnalysisLogger {

    static let shared = AnalysisLogger()
    private init() {}

    private let maxEntries = 200
    private var cache: [AnalysisLogEntry]?

    private var fileURL: URL? {
        guard let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("analysis_log.json")
    }

    func log(_ entry: AnalysisLogEntry) {
        var entries = loadIfNeeded()
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst(entries.count - maxEntries)
        }
        persist(entries)
    }

    func entries() -> [AnalysisLogEntry] {
        loadIfNeeded()
    }

    func clear() {
        persist([])
    }

    // MARK: - Private

    private func loadIfNeeded() -> [AnalysisLogEntry] {
        if let cache { return cache }
        guard
            let url = fileURL,
            let data = try? Data(contentsOf: url),
            let entries = try? JSONDecoder().decode([AnalysisLogEntry].self, from: data)
        else {
            cache = []
            return []
        }
        cache = entries
        return entries
    }

    private func persist(_ entries: [AnalysisLogEntry]) {
        cache = entries
        guard let url = fileURL, let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
