//
//  OpenAIAPIClient.swift
//  ShotTidy
//
//  Анализ скриншотов через GPT-4o Vision.
//

import Foundation
import UIKit

// MARK: - Models

struct ScreenshotAnalysis: Decodable {
    let appName:  String?
    let category: String?
    let summary:  String?
    let tags:     [String]?
    let mainIdea: String?
}

// MARK: - Errors

enum OpenAIError: LocalizedError {
    case noAPIKey
    case invalidImage
    case httpError(Int, String)
    case decodingFailed(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "API-ключ не настроен. Перейдите в Настройки и введите ключ OpenAI."
        case .invalidImage:
            return "Не удалось обработать изображение."
        case .httpError(let code, let body):
            return "Ошибка HTTP \(code): \(body)"
        case .decodingFailed(let detail):
            return "Не удалось разобрать ответ: \(detail)"
        case .networkError(let err):
            return "Ошибка сети: \(err.localizedDescription)"
        }
    }
}

// MARK: - Client

final class OpenAIAPIClient {

    static let shared = OpenAIAPIClient()
    private init() {}

    private let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!

    // MARK: - Analyze

    func analyzeScreenshot(_ image: UIImage) async throws -> ScreenshotAnalysis {
        // 1. API ключ из Config.swift
        let apiKey = Config.openAIKey
        guard !apiKey.isEmpty, apiKey != "ВСТАВЬ_СЮДА_НОВЫЙ_КЛЮЧ" else {
            throw OpenAIError.noAPIKey
        }

        // 2. Сжимаем изображение до 512px (экономия токенов)
        let resized = image.resized(toMaxDimension: 512)
        guard let imageData = resized.jpegData(compressionQuality: 0.75) else {
            throw OpenAIError.invalidImage
        }
        let base64 = imageData.base64EncodedString()

        // 3. Формируем запрос
        let prompt = """
        Analyze this screenshot and return ONLY a JSON object with these fields:
        {
          "appName": "<app or service name, or null if unknown>",
          "category": "<one of: UI Design | Development | Productivity | Social | Finance | Education | Entertainment | Other>",
          "summary": "<1-2 sentences describing what is shown>",
          "tags": ["<tag1>", "<tag2>", "<tag3>"],
          "mainIdea": "<one short phrase — the core concept>"
        }
        No markdown, no extra text — pure JSON only.
        """

        let body: [String: Any] = [
            "model": "gpt-4o",
            "response_format": ["type": "json_object"],
            "max_tokens": 400,
            "messages": [[
                "role": "user",
                "content": [
                    [
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64)",
                            "detail": "low"
                        ]
                    ],
                    [
                        "type": "text",
                        "text": prompt
                    ]
                ]
            ]]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 30

        // 4. Выполняем запрос
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw OpenAIError.networkError(error)
        }

        // 5. Проверяем HTTP статус
        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let body = String(data: data, encoding: .utf8) ?? "no body"
            throw OpenAIError.httpError(http.statusCode, body)
        }

        // 6. Парсим ответ OpenAI → извлекаем content
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let message = choices.first?["message"] as? [String: Any],
            let content = message["content"] as? String,
            let contentData = content.data(using: .utf8)
        else {
            let raw = String(data: data, encoding: .utf8) ?? ""
            throw OpenAIError.decodingFailed(raw)
        }

        // 7. Декодируем ScreenshotAnalysis из content
        do {
            return try JSONDecoder().decode(ScreenshotAnalysis.self, from: contentData)
        } catch {
            throw OpenAIError.decodingFailed(error.localizedDescription)
        }
    }
}

