//
//  OpenAIAPIClient.swift
//  ShotTidy
//
//  Screenshot analysis via GPT-4o Vision.
//  Returns a list of structured items (DraftItem) across various categories.
//

import Foundation
import UIKit

// MARK: - Errors

enum OpenAIError: LocalizedError {
    case noAPIKey
    case invalidImage
    case httpError(Int, String)
    case refused(String)          // content: null + refusal field
    case emptyResponse            // content: null without refusal
    case decodingFailed(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "API key is not configured. Go to Settings and enter your OpenAI key."
        case .invalidImage:
            return "Failed to process the image."
        case .httpError(let code, _):
            if code == 401 { return "Invalid API key. Check your key in Settings." }
            if code == 429 { return "OpenAI rate limit exceeded. Please wait a moment." }
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

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    // MARK: - Analyze screenshot -> [DraftItem]

    func analyzeScreenshot(
        _ image: UIImage,
        screenshotId: UUID? = nil
    ) async throws -> [DraftItem] {

        let apiKey = KeychainManager.shared.openAIAPIKey ?? Config.openAIKey
        guard !apiKey.isEmpty, apiKey != "INSERT_YOUR_KEY_HERE" else {
            throw OpenAIError.noAPIKey
        }

        // "auto" — OpenAI chooses low/high automatically; safer for the content filter
        let resized = image.resized(toMaxDimension: 1024)
        guard let imageData = resized.jpegData(compressionQuality: 0.75) else {
            throw OpenAIError.invalidImage
        }
        let base64 = imageData.base64EncodedString()

        let body: [String: Any] = [
            "model": "gpt-4o",
            "response_format": ["type": "json_object"],
            "max_tokens": 2000,
            "messages": [[
                "role": "user",
                "content": [
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64)",
                            "detail": "auto"
                        ]
                    ],
                    [
                        "type": "text",
                        "text": Self.analysisPrompt
                    ]
                ]
            ]]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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
            // Try to extract something from content for diagnostics
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

    // MARK: - Prompt

    static let analysisPrompt = """
    Please look at this screenshot and extract any useful information you can see.
    Return a JSON object with an "items" array containing the extracted data.

    Each item in the array should have these fields (use empty string "" for missing values):
    {
      "category": one of the category keys listed below,
      "title": the main text or name,
      "subtitle": secondary information,
      "link": a URL if present, otherwise "",
      "extra1": a third relevant field,
      "extra2": a fourth relevant field,
      "notes": any additional details
    }

    Category keys and how to fill the fields:
    - "shopping"         — title=product name, subtitle=price, link=product URL, extra1=store name, extra2=currency
    - "places"           — title=place name, subtitle=address, link=maps URL, extra1=city, extra2=country
    - "appsServices"     — title=app/service name, subtitle=description, link=website, extra1=platform, extra2=category
    - "languageLearning" — title=word or phrase, subtitle=translation, extra1=language, extra2=example
    - "prompts"          — title=prompt text, subtitle=use case, extra1=AI tool
    - "health"           — title=health tip or info, subtitle=type, extra1=source
    - "recipes"          — title=dish name, subtitle=ingredients, link=recipe URL, extra1=cooking time, notes=steps
    - "books"            — title=book title, subtitle=author, link=buy link, extra1=genre, extra2=year
    - "movies"           — title=title, subtitle=platform, link=watch link, extra1=genre, extra2=year
    - "quotes"           — title=quote text, subtitle=author, link=source
    - "articles"         — title=headline, subtitle=publication, link=article URL, extra1=topic
    - "contacts"         — title=person name, subtitle=phone, link=email, extra1=company, extra2=role
    - "tasks"            — title=task, subtitle=due date, extra1=priority

    Notes:
    - If you see multiple products, places, etc., add each as a separate item.
    - Only include information clearly visible in the screenshot.
    - Return only valid JSON, no other text.
    """
}
