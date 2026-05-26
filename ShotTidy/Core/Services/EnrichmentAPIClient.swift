//
//  EnrichmentAPIClient.swift
//  ShotTidy
//
//  Calls the Supabase `enrich-item` Edge Function, which uses
//  GPT-4o with web search to fill in empty fields for a catalog item.
//

import Foundation

// MARK: - Enriched fields returned by the API

struct EnrichedFields {
    var subtitle: String?
    var link: String?
    var extra1: String?
    var extra2: String?
    var notes: String?

    /// Number of non-nil fields in this result.
    var filledCount: Int {
        [subtitle, link, extra1, extra2, notes].compactMap { $0 }.count
    }

    var isEmpty: Bool { filledCount == 0 }
}

// MARK: - Errors

enum EnrichmentError: LocalizedError {
    case httpError(Int, String)
    case decodingFailed(String)
    case networkError(Error)
    case noFieldsFound

    var errorDescription: String? {
        switch self {
        case .httpError(let code, _):
            if code == 429 { return "Rate limit exceeded. Please wait a moment." }
            if code == 500 { return "Server error. Please try again later." }
            return "Server error (\(code)). Please try again."
        case .decodingFailed(let detail):
            return "Failed to parse search results: \(detail)"
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        case .noFieldsFound:
            return "No additional information found for this item."
        }
    }
}

// MARK: - Client

final class EnrichmentAPIClient {

    static let shared = EnrichmentAPIClient()
    private init() {}

    /// Searches the web for missing fields of the given `CatalogItem`.
    func enrich(_ item: CatalogItem) async throws -> EnrichedFields {
        let schema = item.category.fieldSchema
        return try await enrichFields(
            category: item.category,
            title:    item.title,
            subtitle: item.subtitle ?? "",
            link:     item.link     ?? "",
            extra1:   item.extra1   ?? "",
            extra2:   item.extra2   ?? "",
            notes:    item.notes    ?? "",
            schema:   schema
        )
    }

    /// Searches the web for missing fields given raw string values from the edit form.
    /// Only fields defined in the schema and currently empty are sent for enrichment.
    func enrichFields(
        category: ItemCategory,
        title: String,
        subtitle: String,
        link: String,
        extra1: String,
        extra2: String,
        notes: String,
        schema: ItemCategory.FieldSchema
    ) async throws -> EnrichedFields {

        var body: [String: String] = [
            "category": category.rawValue,
            "title":    title,
        ]
        if schema.subtitleLabel != nil { body["subtitle"] = subtitle }
        if schema.linkLabel     != nil { body["link"]     = link }
        if schema.extra1Label   != nil { body["extra1"]   = extra1 }
        if schema.extra2Label   != nil { body["extra2"]   = extra2 }
        if schema.notesLabel    != nil { body["notes"]    = notes }

        return try await send(body: body)
    }

    // MARK: - Shared transport

    private func send(body: [String: String]) async throws -> EnrichedFields {
        var request = URLRequest(url: Config.enrichEndpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 45

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw EnrichmentError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            throw EnrichmentError.httpError(http.statusCode, bodyStr)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let preview = String(data: data, encoding: .utf8)?.prefix(120) ?? ""
            throw EnrichmentError.decodingFailed(String(preview))
        }

        let result = EnrichedFields(
            subtitle: json["subtitle"] as? String,
            link:     json["link"]     as? String,
            extra1:   json["extra1"]   as? String,
            extra2:   json["extra2"]   as? String,
            notes:    json["notes"]    as? String
        )

        if result.isEmpty { throw EnrichmentError.noFieldsFound }
        return result
    }
}
