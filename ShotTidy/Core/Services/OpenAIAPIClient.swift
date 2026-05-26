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

// MARK: - Errors

enum OpenAIError: LocalizedError {
    case invalidImage
    case httpError(Int, String)
    case refused(String)          // content: null + refusal field
    case emptyResponse            // content: null without refusal
    case decodingFailed(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Failed to process the image."
        case .httpError(let code, _):
            if code == 401 { return "Authorization error. Check your Supabase configuration." }
            if code == 429 { return "Rate limit exceeded. Please wait a moment." }
            if code == 500 { return "Server error. Make sure OPENAI_API_KEY is set in Supabase Secrets." }
            return "Server error (\(code)). Please try again."
        case .refused:
            return "GPT-4o could not analyze this screenshot. Try a different image."
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

final class OpenAIAPIClient {

    static let shared = OpenAIAPIClient()
    private init() {}

    // MARK: - Analyze screenshot -> [DraftItem]

    func analyzeScreenshot(
        _ image: UIImage,
        screenshotId: UUID? = nil
    ) async throws -> [DraftItem] {

        let resized = image.resized(toMaxDimension: 1024)
        guard let imageData = resized.jpegData(compressionQuality: 0.75) else {
            throw OpenAIError.invalidImage
        }
        let base64 = imageData.base64EncodedString()

        let body: [String: Any] = ["image": base64]

        var request = URLRequest(url: Config.analyzeEndpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw OpenAIError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let bodyStr = String(data: data, encoding: .utf8) ?? ""
            throw OpenAIError.httpError(http.statusCode, bodyStr)
        }

        return try parseItems(from: data, screenshotId: screenshotId)
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
                let category = ItemCategory(rawValue: categoryStr),
                let title = dict["title"] as? String,
                !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return nil }

            return DraftItem(
                category: category,
                title: title,
                subtitle: dict["subtitle"] as? String ?? "",
                link: dict["link"] as? String ?? "",
                extra1: dict["extra1"] as? String ?? "",
                extra2: dict["extra2"] as? String ?? "",
                notes: dict["notes"] as? String ?? "",
                sourceScreenshotId: screenshotId
            )
        }
    }
}
