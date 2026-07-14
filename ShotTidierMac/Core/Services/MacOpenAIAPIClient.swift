//
//  MacOpenAIAPIClient.swift
//  ShotTidierMac
//
//  Screenshot analysis via Supabase Edge Function.
//  Uses NSImage instead of UIImage; transport and response parsing are shared
//  (SupabaseFunctionClient).
//

import Foundation
import AppKit

// MARK: - Errors (iOS counterpart lives in OpenAIAPIClient.swift)

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

    init(_ transportError: SupabaseFunctionClient.TransportError) {
        switch transportError {
        case .network(let err):            self = .networkError(err)
        case .http(let code, let message): self = .httpError(code, message ?? "")
        case .quotaExceeded(let message):  self = .quotaExceeded(message)
        case .refused(let refusal):        self = .refused(refusal)
        case .emptyResponse:               self = .emptyResponse
        case .decodingFailed(let detail):  self = .decodingFailed(detail)
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

        do {
            let data = try await SupabaseFunctionClient.postJSON(body, to: Config.analyzeEndpoint)
            let items = try SupabaseFunctionClient.openAIItems(from: data)
            return items.map { dict in
                DraftItem(
                    categoryKey: dict["category"] ?? "",
                    title: dict["title"] ?? "",
                    subtitle: dict["subtitle"] ?? "",
                    link: dict["link"] ?? "",
                    extra1: dict["extra1"] ?? "",
                    extra2: dict["extra2"] ?? "",
                    notes: dict["notes"] ?? "",
                    suggestedCategoryName: dict["suggestedCategoryName"] ?? "",
                    sourceScreenshotId: screenshotId
                )
            }
        } catch let transportError as SupabaseFunctionClient.TransportError {
            throw OpenAIError(transportError)
        }
    }
}
