//
//  MacOpenAIAPIClient.swift
//  ShotTidierMac
//
//  Screenshot analysis via Supabase Edge Function.
//  Uses NSImage instead of UIImage.
//

import Foundation
import AppKit

// MARK: - Shared types (iOS counterparts live in OpenAIAPIClient.swift)

struct CategoryPromptInfo: Encodable {
    let key: String
    let name: String
    let hint: String
}

enum OpenAIError: LocalizedError {
    case invalidImage
    case httpError(Int, String)
    case quotaExceeded(String)    // 429 with a server-provided message
    case refused(String)
    case emptyResponse
    case decodingFailed(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Failed to process the image."
        case .quotaExceeded(let message):
            return message
        case .httpError(let code, _):
            if code == 401 { return "Authorization error. Check your Supabase configuration." }
            if code == 429 { return "Rate limit exceeded. Please wait a moment." }
            if code == 500 { return "Server error. Make sure OPENAI_API_KEY is set in Supabase Secrets." }
            return "Server error (\(code)). Please try again."
        case .refused:
            return "AI could not analyze this screenshot. Try a different image."
        case .emptyResponse:
            return "Empty response from the API. Please try again."
        case .decodingFailed(let detail):
            return "Failed to parse the response: \(detail)"
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        }
    }
}

// MARK: - Client

final class MacOpenAIAPIClient {

    static let shared = MacOpenAIAPIClient()
    private init() {}

    func analyzeScreenshot(
        _ image: NSImage,
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
        return "Rate limit exceeded. Please wait a moment."
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

        if let refusal = message["refusal"] as? String, !refusal.isEmpty {
            throw OpenAIError.refused(refusal)
        }

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
