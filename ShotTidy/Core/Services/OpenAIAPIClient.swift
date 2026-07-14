//
//  OpenAIAPIClient.swift
//  ShotTidy
//
//  Screenshot analysis via Supabase Edge Function (analyze-screenshot).
//  The Edge Function proxies the request to GPT-4o; the OpenAI key never
//  leaves the server.
//

import Foundation
import UIKit

// MARK: - Custom category payload

/// Lightweight category info sent to the analysis function so the AI can match
/// (and suggest) user-defined categories.
struct CategoryPromptInfo: Encodable {
    let key: String
    let name: String
    let hint: String
}

// MARK: - Errors

enum OpenAIError: LocalizedError {
    case invalidImage
    case httpError(Int, String)
    case quotaExceeded(String)    // 429 with a server-provided message
    case refused(String)          // content: null + refusal field
    case emptyResponse            // content: null without refusal
    case decodingFailed(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return String(localized: "Failed to process the image.", bundle: AppLocale.bundle)
        case .quotaExceeded(let message):
            return message
        case .httpError(let code, _):
            if code == 401 { return String(localized: "Authorization error. Check your Supabase configuration.", bundle: AppLocale.bundle) }
            if code == 429 { return String(localized: "Rate limit exceeded. Please wait a moment.", bundle: AppLocale.bundle) }
            if code == 500 { return String(localized: "Server error. Please try again later.", bundle: AppLocale.bundle) }
            return String(localized: "Server error (\(code)). Please try again.", bundle: AppLocale.bundle)
        case .refused:
            return String(localized: "AI could not analyze this screenshot. Try a different image.", bundle: AppLocale.bundle)
        case .emptyResponse:
            return String(localized: "Empty response from the API. Please try again.", bundle: AppLocale.bundle)
        case .decodingFailed(let detail):
            return String(localized: "Failed to parse the response: \(detail)", bundle: AppLocale.bundle)
        case .networkError(let err):
            return String(localized: "Network error: \(err.localizedDescription)", bundle: AppLocale.bundle)
        }
    }
}

// MARK: - Client

final class OpenAIAPIClient {

    static let shared = OpenAIAPIClient()
    private init() {}

    // MARK: - Analyze screenshot -> [DraftItem]

    func analyzeScreenshot(
        _ image: UIImage,
        customCategories: [CategoryPromptInfo] = [],
        allowNewCategory: Bool = false,
        screenshotId: UUID? = nil
    ) async throws -> [DraftItem] {

        let resized = image.resized(toMaxDimension: 1024)
        guard let imageData = resized.jpegData(compressionQuality: 0.75) else {
            throw OpenAIError.invalidImage
        }
        let base64 = imageData.base64EncodedString()

        var body: [String: Any] = [
            "image": base64,
            "allowNewCategory": allowNewCategory,
        ]
        if !customCategories.isEmpty {
            body["customCategories"] = customCategories.map {
                ["key": $0.key, "name": $0.name, "hint": $0.hint]
            }
        }

        var request = URLRequest(url: Config.analyzeEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

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
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            if http.statusCode == 429 {
                throw OpenAIError.quotaExceeded(Self.serverErrorMessage(from: data))
            }
            throw OpenAIError.httpError(http.statusCode, bodyStr)
        }

        return try parseItems(from: data, screenshotId: screenshotId)
    }

    private func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await URLSession.shared.data(for: request)
        } catch {
            throw OpenAIError.networkError(error)
        }
    }

    /// Extracts the "error" message from a JSON error body, with a fallback.
    private static func serverErrorMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["error"] as? String, !message.isEmpty {
            return message
        }
        return String(localized: "Rate limit exceeded. Please wait a moment.", bundle: AppLocale.bundle)
    }

    // MARK: - Parse

    private func parseItems(from data: Data, screenshotId: UUID?) throws -> [DraftItem] {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any]
        else {
            throw OpenAIError.decodingFailed("Unexpected API response format")
        }

        // Handle refusal (content: null + refusal field)
        if let refusal = message["refusal"] as? String, !refusal.isEmpty {
            throw OpenAIError.refused(refusal)
        }

        // content may be null if the model refused without an explicit refusal field
        guard let content = message["content"] as? String else {
            throw OpenAIError.emptyResponse
        }

        guard
            let contentData = content.data(using: .utf8),
            let contentJson = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any],
            let items = contentJson["items"] as? [[String: Any]]
        else {
            let preview = String(content.prefix(120))
            throw OpenAIError.decodingFailed("Expected an items array. Got: \(preview)")
        }

        return items.compactMap { dict -> DraftItem? in
            guard
                let categoryStr = dict["category"] as? String,
                !categoryStr.isEmpty,
                let title = dict["title"] as? String,
                !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return nil }

            // Accept any non-empty key: built-in raw value, custom key, or "__new__".
            // Resolution happens at display time via CategoryStore (with fallback).
            return DraftItem(
                categoryKey: categoryStr,
                title: title,
                subtitle: dict["subtitle"] as? String ?? "",
                link: dict["link"] as? String ?? "",
                extra1: dict["extra1"] as? String ?? "",
                extra2: dict["extra2"] as? String ?? "",
                notes: dict["notes"] as? String ?? "",
                suggestedCategoryName: dict["suggestedCategoryName"] as? String ?? "",
                sourceScreenshotId: screenshotId
            )
        }
    }
}
