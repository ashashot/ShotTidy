//
//  ShareEnrichmentClient.swift
//  ShotTidyShare
//
//  Self-contained enrichment client for the Share Extension.
//  Mirrors EnrichmentAPIClient from the main app without importing any main-app types.
//  Calls the Supabase `enrich-item` Edge Function (GPT-4o web search).
//

import Foundation

// MARK: - Result

struct ShareEnrichedFields {
    let subtitle: String?
    let link: String?
    let extra1: String?
    let extra2: String?
    let notes: String?

    var filledCount: Int {
        [subtitle, link, extra1, extra2, notes].compactMap { $0 }.count
    }

    var isEmpty: Bool { filledCount == 0 }
}

// MARK: - Errors

enum ShareEnrichmentError: LocalizedError {
    case networkError(Error)
    case serverError(Int)
    case decodingFailed
    case noFieldsFound

    var errorDescription: String? {
        switch self {
        case .networkError(let e): return "Network error: \(e.localizedDescription)"
        case .serverError(let c):  return "Server error (\(c)). Please try again."
        case .decodingFailed:      return "Could not parse search results."
        case .noFieldsFound:       return "No additional information found."
        }
    }
}

// MARK: - Client

final class ShareEnrichmentClient {

    static let shared = ShareEnrichmentClient()
    private init() {}

    private let supabaseURL     = "https://qpxvnnkewwolzglynrgj.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFweHZubmtld3dvbHpnbHlucmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3NDkzMzksImV4cCI6MjA5NTMyNTMzOX0.fYzLDOILNm3I2TU6QobG5HGQQxe8kJAfPCI9kSABpec"

    private var enrichEndpoint: URL {
        URL(string: "\(supabaseURL)/functions/v1/enrich-item")!
    }

    /// Searches the web for missing fields of a `PendingDraftItem`.
    /// `schema` is the `ShareFieldSchema` for the item's category — used to decide
    /// which fields to include in the request.
    func enrich(
        item: PendingDraftItem,
        schema: ShareFieldSchema
    ) async throws -> ShareEnrichedFields {

        var body: [String: String] = [
            "category": item.categoryKey,
            "title":    item.title,
        ]
        if schema.subtitleLabel != nil { body["subtitle"] = item.subtitle }
        if schema.linkLabel     != nil { body["link"]     = item.link }
        if schema.extra1Label   != nil { body["extra1"]   = item.extra1 }
        if schema.extra2Label   != nil { body["extra2"]   = item.extra2 }
        if schema.notesLabel    != nil { body["notes"]    = item.notes }

        var request = URLRequest(url: enrichEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 45

        let token = await SupabaseAuthManager.shared.bearerToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ShareEnrichmentError.networkError(error)
        }

        // Expired session — refresh once and retry.
        if let http = response as? HTTPURLResponse, http.statusCode == 401,
           let fresh = await SupabaseAuthManager.shared.recoverFromAuthFailure() {
            request.setValue("Bearer \(fresh)", forHTTPHeaderField: "Authorization")
            do {
                (data, response) = try await URLSession.shared.data(for: request)
            } catch {
                throw ShareEnrichmentError.networkError(error)
            }
        }

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            throw ShareEnrichmentError.serverError(http.statusCode)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ShareEnrichmentError.decodingFailed
        }

        let result = ShareEnrichedFields(
            subtitle: json["subtitle"] as? String,
            link:     json["link"]     as? String,
            extra1:   json["extra1"]   as? String,
            extra2:   json["extra2"]   as? String,
            notes:    json["notes"]    as? String
        )

        if result.isEmpty { throw ShareEnrichmentError.noFieldsFound }
        return result
    }
}
