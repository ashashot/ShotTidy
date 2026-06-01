//
//  CategorySuggestionClient.swift
//  ShotTidy
//
//  Calls the Supabase `suggest-category-fields` Edge Function to propose an
//  icon, field labels, and an AI hint for a user-defined category (Pro feature).
//

import Foundation

// MARK: - Suggested layout

struct SuggestedCategoryLayout {
    var iconName: String
    var titleLabel: String
    var subtitleLabel: String
    var linkLabel: String
    var extra1Label: String
    var extra2Label: String
    var notesLabel: String
    var aiHint: String
}

// MARK: - Errors

enum CategorySuggestionError: LocalizedError {
    case httpError(Int, String)
    case decodingFailed(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .httpError(let code, _):
            if code == 429 { return "Rate limit exceeded. Please wait a moment." }
            if code == 500 { return "Server error. Please try again later." }
            return "Server error (\(code)). Please try again."
        case .decodingFailed(let detail):
            return "Failed to parse the suggestion: \(detail)"
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        }
    }
}

// MARK: - Client

final class CategorySuggestionClient {

    static let shared = CategorySuggestionClient()
    private init() {}

    /// Asks the AI to design a field layout for a category given its name and hint.
    func suggestFields(name: String, hint: String) async throws -> SuggestedCategoryLayout {
        var request = URLRequest(url: Config.suggestCategoryFieldsEndpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(
            withJSONObject: ["name": name, "hint": hint]
        )
        request.timeoutInterval = 45

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw CategorySuggestionError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            throw CategorySuggestionError.httpError(http.statusCode, bodyStr)
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let preview = String(data: data, encoding: .utf8)?.prefix(120) ?? ""
            throw CategorySuggestionError.decodingFailed(String(preview))
        }

        func str(_ key: String) -> String { (json[key] as? String) ?? "" }

        let title = str("titleLabel").isEmpty ? "Title" : str("titleLabel")
        let icon  = str("iconName").isEmpty ? "tag.fill" : str("iconName")

        return SuggestedCategoryLayout(
            iconName: icon,
            titleLabel: title,
            subtitleLabel: str("subtitleLabel"),
            linkLabel: str("linkLabel"),
            extra1Label: str("extra1Label"),
            extra2Label: str("extra2Label"),
            notesLabel: str("notesLabel"),
            aiHint: str("aiHint")
        )
    }
}
