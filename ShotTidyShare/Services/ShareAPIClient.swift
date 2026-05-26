//
//  ShareAPIClient.swift
//  ShotTidyShare
//
//  Self-contained proxy client for the Share Extension.
//  Calls the Supabase Edge Function analyze-screenshot instead of OpenAI directly.
//  Returns [PendingDraftItem] — no dependency on the main app's models.
//

import Foundation
import UIKit

// MARK: - Errors

enum ShareAPIError: LocalizedError {
    case invalidImage
    case networkError(Error)
    case unauthorized
    case rateLimited
    case serverError(Int)
    case refused
    case emptyResponse
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Could not process the image."
        case .networkError(let err):
            return "Network error: \(err.localizedDescription)"
        case .unauthorized:
            return "Authorization error. Check your Supabase configuration."
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .serverError(let code):
            return "Server error (\(code)). Please try again."
        case .refused:
            return "GPT-4o could not analyze this screenshot."
        case .emptyResponse:
            return "Empty response. Please try again."
        case .decodingFailed:
            return "Could not parse the AI response. Please try again."
        }
    }
}

// MARK: - Client

final class ShareAPIClient {

    static let shared = ShareAPIClient()
    private init() {}

    // Supabase credentials — anon key is a publishable key, safe to embed.
    private let supabaseURL     = "https://qpxvnnkewwolzglynrgj.supabase.co"
    private let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFweHZubmtld3dvbHpnbHlucmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3NDkzMzksImV4cCI6MjA5NTMyNTMzOX0.fYzLDOILNm3I2TU6QobG5HGQQxe8kJAfPCI9kSABpec"

    private var analyzeEndpoint: URL {
        URL(string: "\(supabaseURL)/functions/v1/analyze-screenshot")!
    }

    func analyze(image: UIImage) async throws -> [PendingDraftItem] {
        let resized = resize(image, maxDimension: 1024)
        guard let imageData = resized.jpegData(compressionQuality: 0.75) else {
            throw ShareAPIError.invalidImage
        }
        let base64 = imageData.base64EncodedString()

        let body: [String: Any] = ["image": base64]

        var request = URLRequest(url: analyzeEndpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw ShareAPIError.networkError(error)
        }

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            if http.statusCode == 401 { throw ShareAPIError.unauthorized }
            if http.statusCode == 429 { throw ShareAPIError.rateLimited }
            throw ShareAPIError.serverError(http.statusCode)
        }

        return try parseItems(from: data)
    }

    // MARK: - Parse

    private func parseItems(from data: Data) throws -> [PendingDraftItem] {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any]
        else {
            throw ShareAPIError.decodingFailed
        }

        if let refusal = message["refusal"] as? String, !refusal.isEmpty {
            throw ShareAPIError.refused
        }

        guard let content = message["content"] as? String else {
            throw ShareAPIError.emptyResponse
        }

        guard
            let contentData = content.data(using: .utf8),
            let contentJson = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any],
            let items = contentJson["items"] as? [[String: Any]]
        else {
            throw ShareAPIError.decodingFailed
        }

        return items.compactMap { dict -> PendingDraftItem? in
            guard
                let category = dict["category"] as? String,
                let title = dict["title"] as? String,
                !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return nil }

            return PendingDraftItem(
                categoryKey: category,
                title: title,
                subtitle: dict["subtitle"] as? String ?? "",
                link: dict["link"] as? String ?? "",
                extra1: dict["extra1"] as? String ?? "",
                extra2: dict["extra2"] as? String ?? "",
                notes: dict["notes"] as? String ?? ""
            )
        }
    }

    // MARK: - Image resize

    private func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return image }
        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
