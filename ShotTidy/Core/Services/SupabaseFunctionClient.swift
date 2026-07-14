//
//  SupabaseFunctionClient.swift
//  ShotTidy
//
//  Shared transport for Supabase Edge Function calls: per-user bearer token
//  from the anonymous session, one refresh-and-retry on 401, JSON error
//  extraction, and the common OpenAI chat-completions response parse used by
//  the analyze functions. Foundation-only — compiled into the iOS app, the
//  macOS app and the Safari extension.
//

import Foundation

// MARK: - Custom category payload

/// Lightweight category info sent to the analysis functions so the AI can
/// match (and suggest) user-defined categories.
struct CategoryPromptInfo: Encodable {
    let key: String
    let name: String
    let hint: String
}

// MARK: - Client

enum SupabaseFunctionClient {

    enum TransportError: Error {
        case network(Error)
        case http(statusCode: Int, serverMessage: String?)
        case quotaExceeded(String)   // 429 with a server-provided message
        case refused(String)         // content: null + refusal field
        case emptyResponse           // content: null without refusal
        case decodingFailed(String)
    }

    /// POSTs a JSON body with the per-user bearer token; retries once with a
    /// refreshed token after a 401. Returns the body of a 200 response.
    static func postJSON(
        _ body: [String: Any],
        to url: URL,
        timeout: TimeInterval = 60
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = timeout

        let token = await SupabaseAuthManager.shared.bearerToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var (data, response) = try await send(request)

        // Expired session — refresh once and retry.
        if let http = response as? HTTPURLResponse, http.statusCode == 401,
           let fresh = await SupabaseAuthManager.shared.recoverFromAuthFailure() {
            request.setValue("Bearer \(fresh)", forHTTPHeaderField: "Authorization")
            (data, response) = try await send(request)
        }

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let message = serverErrorMessage(from: data)
            if http.statusCode == 429 {
                throw TransportError.quotaExceeded(
                    message ?? "Rate limit exceeded. Please wait a moment."
                )
            }
            throw TransportError.http(statusCode: http.statusCode, serverMessage: message)
        }
        return data
    }

    private static func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            throw TransportError.network(error)
        }
    }

    /// Extracts the "error" message from a JSON error body, nil when absent.
    static func serverErrorMessage(from data: Data) -> String? {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let message = json["error"] as? String, !message.isEmpty
        else { return nil }
        return message
    }

    // MARK: - OpenAI response parse

    /// Parses the raw OpenAI chat-completions payload returned by the analyze
    /// functions: choices[0].message.content → { "items": [...] }.
    /// Items with an empty category or title are dropped; missing fields
    /// become empty strings.
    static func openAIItems(from data: Data) throws -> [[String: String]] {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any]
        else {
            throw TransportError.decodingFailed("Unexpected API response format")
        }

        if let refusal = message["refusal"] as? String, !refusal.isEmpty {
            throw TransportError.refused(refusal)
        }

        guard let content = message["content"] as? String else {
            throw TransportError.emptyResponse
        }

        guard
            let contentData = content.data(using: .utf8),
            let contentJson = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any],
            let rawItems = contentJson["items"] as? [[String: Any]]
        else {
            let preview = String(content.prefix(120))
            throw TransportError.decodingFailed("Expected an items array. Got: \(preview)")
        }

        return rawItems.compactMap { dict in
            guard
                let category = dict["category"] as? String, !category.isEmpty,
                let title = dict["title"] as? String,
                !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return nil }
            return [
                "category": category,
                "title": title,
                "subtitle": dict["subtitle"] as? String ?? "",
                "link": dict["link"] as? String ?? "",
                "extra1": dict["extra1"] as? String ?? "",
                "extra2": dict["extra2"] as? String ?? "",
                "notes": dict["notes"] as? String ?? "",
                "suggestedCategoryName": dict["suggestedCategoryName"] as? String ?? "",
            ]
        }
    }
}
