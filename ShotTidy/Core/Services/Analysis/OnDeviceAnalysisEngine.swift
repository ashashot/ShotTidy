//
//  OnDeviceAnalysisEngine.swift
//  ShotTidy
//
//  Screenshot analysis with Apple's on-device Foundation Models (iOS 27+).
//  The iOS 27 system language model accepts image attachments, so the whole
//  pipeline — reading the screenshot and producing structured catalog items —
//  runs on the device. Nothing is uploaded.
//
//  Output mirrors the cloud path (`SupabaseFunctionClient.openAIItems`): an
//  array of string dictionaries with the same keys, so callers map them into
//  `DraftItem` / `PendingDraftItem` exactly like the GPT-4o response.
//
//  Cross-compiled into the Share Extension. Only Foundation + FoundationModels.
//
//  Build note: the image-attachment API exists only in the iOS 27 SDK
//  (Xcode 27 / Swift 6.4). With an older toolchain the engine compiles as
//  permanently unavailable and the cloud path is used — see `availability`.
//

import Foundation
import CoreGraphics
import ImageIO
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Availability

enum OnDeviceAnalysisAvailability: Equatable, Sendable {
    case available
    /// Device runs iOS 26 (or the app was built with a pre-iOS-27 SDK).
    case requiresNewerOS
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    /// Model assets are still downloading or otherwise not ready.
    case modelNotReady
    /// The system model exists but cannot take image input.
    case visionNotSupported

    var isAvailable: Bool { self == .available }

    /// Human-readable status for Settings and fallback notices.
    var localizedDescription: String {
        switch self {
        case .available:
            return String(localized: "On-device analysis is ready.", bundle: AppLocale.bundle)
        case .requiresNewerOS:
            return String(localized: "Requires iOS 27 or later.", bundle: AppLocale.bundle)
        case .deviceNotEligible:
            return String(localized: "This device does not support Apple Intelligence.", bundle: AppLocale.bundle)
        case .appleIntelligenceNotEnabled:
            return String(localized: "Turn on Apple Intelligence in Settings to use the on-device model.", bundle: AppLocale.bundle)
        case .modelNotReady:
            return String(localized: "The on-device model is still downloading. Try again later.", bundle: AppLocale.bundle)
        case .visionNotSupported:
            return String(localized: "The on-device model on this device cannot analyze images.", bundle: AppLocale.bundle)
        }
    }
}

// MARK: - Errors

enum OnDeviceAnalysisError: LocalizedError {
    case unavailable(OnDeviceAnalysisAvailability)
    case invalidImage
    /// Model declined the request (safety guardrails or explicit refusal).
    case refused
    case contextSizeExceeded
    case rateLimited
    case timeout
    case unsupportedLanguage
    case decodingFailed(String)
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .unavailable(let availability):
            return availability.localizedDescription
        case .invalidImage:
            return String(localized: "Failed to process the image.", bundle: AppLocale.bundle)
        case .refused:
            return String(localized: "The on-device model could not analyze this screenshot.", bundle: AppLocale.bundle)
        case .contextSizeExceeded:
            return String(localized: "This screenshot is too complex for the on-device model.", bundle: AppLocale.bundle)
        case .rateLimited:
            return String(localized: "The on-device model is busy. Please try again.", bundle: AppLocale.bundle)
        case .timeout:
            return String(localized: "On-device analysis timed out.", bundle: AppLocale.bundle)
        case .unsupportedLanguage:
            return String(localized: "The on-device model does not support the current language.", bundle: AppLocale.bundle)
        case .decodingFailed(let detail):
            return String(localized: "Failed to parse the on-device result: \(detail)", bundle: AppLocale.bundle)
        case .underlying(let error):
            return String(localized: "On-device analysis failed: \(error.localizedDescription)", bundle: AppLocale.bundle)
        }
    }
}

// MARK: - Engine

/// Serializes all on-device requests: the system model handles one request
/// at a time and parallel sessions would only contend for the Neural Engine.
actor OnDeviceAnalysisEngine {

    static let shared = OnDeviceAnalysisEngine()
    private init() {}

    /// Current availability of on-device screenshot analysis. Cheap to query;
    /// re-check before every run because Apple Intelligence can be toggled or
    /// finish downloading while the app is open.
    nonisolated static var availability: OnDeviceAnalysisAvailability {
        #if canImport(FoundationModels) && compiler(>=6.4)
        if #available(iOS 27.0, *) {
            return FoundationModelsBridge.availability
        }
        #endif
        return .requiresNewerOS
    }

    /// Analyzes one screenshot and returns raw items keyed like the cloud
    /// response: category, title, subtitle, link, extra1, extra2, notes,
    /// suggestedCategoryName. Items with an empty title are dropped.
    func analyze(
        cgImage: CGImage,
        orientation: CGImagePropertyOrientation,
        customCategories: [AnalysisCategoryHint],
        allowNewCategory: Bool
    ) async throws -> [[String: String]] {
        #if canImport(FoundationModels) && compiler(>=6.4)
        if #available(iOS 27.0, *) {
            return try await FoundationModelsBridge.analyze(
                cgImage: cgImage,
                orientation: orientation,
                customCategories: customCategories,
                allowNewCategory: allowNewCategory
            )
        }
        #endif
        throw OnDeviceAnalysisError.unavailable(.requiresNewerOS)
    }
}

// MARK: - Prompt (shared wording with the Edge Function)

enum OnDeviceAnalysisPrompt {

    /// Stable key of the "needs a new category" placeholder — same as `DraftItem.newCategoryKey`.
    static let newCategoryKey = "__new__"

    /// Built-in keys in the order they are presented to the model.
    static let builtInCategoryKeys = [
        "shopping", "places", "appsServices", "languageLearning", "prompts", "health",
        "recipes", "books", "movies", "quotes", "articles", "contacts", "tasks",
    ]

    /// Upper bound on extracted items per screenshot — keeps the response
    /// inside the on-device context window.
    static let maxItems = 15

    /// Custom categories beyond this are ignored to protect the token budget.
    static let maxCustomCategories = 30

    /// System instructions. Static text only — never user content.
    static let instructions = """
    You are a data-extraction assistant for a personal catalog app. \
    The user attaches a screenshot. Extract every useful item visible in it and return structured data.

    Category keys and how to fill the fields:
    - shopping: title=product name, subtitle=price, link=product URL, extra1=store name, extra2=currency
    - places: title=place name, subtitle=address, link=maps URL, extra1=city, extra2=country
    - appsServices: title=app or service name, subtitle=description, link=website, extra1=platform, extra2=category
    - languageLearning: title=word or phrase, subtitle=translation, extra1=language, extra2=example
    - prompts: title=prompt text, subtitle=use case, extra1=AI tool
    - health: title=health tip or info, subtitle=type, extra1=source
    - recipes: title=dish name, subtitle=ingredients, link=recipe URL, extra1=cooking time, notes=steps
    - books: title=book title, subtitle=author, link=buy link, extra1=genre, extra2=year
    - movies: title=title, subtitle=platform, link=watch link, extra1=genre, extra2=year
    - quotes: title=quote text, subtitle=author, link=source
    - articles: title=headline, subtitle=publication, link=article URL, extra1=topic
    - contacts: title=person name, subtitle=phone, link=email, extra1=company, extra2=role
    - tasks: title=task, subtitle=due date, extra1=priority

    Rules:
    - Add each distinct product, place, book, etc. as a separate item.
    - Copy names, prices, addresses and URLs exactly as shown. DO NOT invent details that are not visible.
    - Leave a field out when the screenshot does not show it.
    - Pick the single best category key for every item.
    """

    /// Per-request prompt. Custom categories are user data, so they belong
    /// here rather than in the instructions.
    static func userPrompt(customCategories: [AnalysisCategoryHint], allowNewCategory: Bool) -> String {
        var text = "Extract the items from the attached screenshot."

        let custom = Array(customCategories.prefix(maxCustomCategories))
        if !custom.isEmpty {
            let lines = custom.map { category -> String in
                let hint = category.hint.trimmingCharacters(in: .whitespacesAndNewlines)
                let suffix = hint.isEmpty ? "" : " — \(hint)"
                return "- \"\(category.key)\" (user category \"\(category.name)\")\(suffix)"
            }
            text += "\n\nThe user also defined these custom categories. Prefer them whenever an item fits:\n"
            text += lines.joined(separator: "\n")
        }

        if allowNewCategory {
            text += """


            If an item does NOT fit any category, use the category "\(newCategoryKey)" and set \
            suggestedCategoryName to a short, human-readable name for a new category (e.g. "Wines", "Gym Workouts"). \
            Group similar items under the same suggested name. Only do this when nothing else is a reasonable fit.
            """
        }
        return text
    }

    /// Every category key the model may emit for this request.
    static func allowedCategoryKeys(customCategories: [AnalysisCategoryHint], allowNewCategory: Bool) -> [String] {
        var keys = builtInCategoryKeys
        keys += customCategories.prefix(maxCustomCategories).map(\.key)
        if allowNewCategory { keys.append(newCategoryKey) }
        return keys
    }
}

// MARK: - Foundation Models bridge (iOS 27 SDK only)

#if canImport(FoundationModels) && compiler(>=6.4)

@available(iOS 27.0, *)
private enum FoundationModelsBridge {

    static var availability: OnDeviceAnalysisAvailability {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            return model.capabilities.contains(.vision) ? .available : .visionNotSupported
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:          return .deviceNotEligible
            case .appleIntelligenceNotEnabled: return .appleIntelligenceNotEnabled
            case .modelNotReady:              return .modelNotReady
            @unknown default:                 return .deviceNotEligible
            }
        }
    }

    static func analyze(
        cgImage: CGImage,
        orientation: CGImagePropertyOrientation,
        customCategories: [AnalysisCategoryHint],
        allowNewCategory: Bool
    ) async throws -> [[String: String]] {
        let current = availability
        guard current.isAvailable else { throw OnDeviceAnalysisError.unavailable(current) }

        let keys = OnDeviceAnalysisPrompt.allowedCategoryKeys(
            customCategories: customCategories, allowNewCategory: allowNewCategory
        )
        let schema: GenerationSchema
        do {
            schema = try makeSchema(categoryKeys: keys, allowNewCategory: allowNewCategory)
        } catch {
            throw OnDeviceAnalysisError.decodingFailed("Schema: \(error.localizedDescription)")
        }

        // One stateless session per screenshot — there is no conversation to keep.
        let session = LanguageModelSession(
            model: SystemLanguageModel.default,
            instructions: OnDeviceAnalysisPrompt.instructions
        )

        let prompt = Prompt {
            Attachment(cgImage, orientation: orientation)
            OnDeviceAnalysisPrompt.userPrompt(
                customCategories: customCategories, allowNewCategory: allowNewCategory
            )
        }

        // Deterministic decoding: extraction should not be creative.
        let options = GenerationOptions(
            samplingMode: .greedy,
            temperature: nil,
            maximumResponseTokens: 1500
        )

        let response: LanguageModelSession.Response<GeneratedContent>
        do {
            response = try await session.respond(
                to: prompt, schema: schema, includeSchemaInPrompt: true, options: options
            )
        } catch {
            throw mapError(error)
        }

        return try parseItems(response.content)
    }

    // MARK: Schema

    /// Builds the response schema at runtime so `category` is constrained to
    /// the exact set of keys valid for this user (built-in + custom + "__new__").
    private static func makeSchema(categoryKeys: [String], allowNewCategory: Bool) throws -> GenerationSchema {
        let string = DynamicGenerationSchema(type: String.self)
        let category = DynamicGenerationSchema(
            name: "CategoryKey",
            description: "Category key that best fits the item",
            anyOf: categoryKeys
        )

        var properties: [DynamicGenerationSchema.Property] = [
            .init(name: "category", description: "Category key that best fits this item", schema: category),
            .init(name: "title", description: "Main name or text of the item, copied from the screenshot", schema: string),
            .init(name: "subtitle", description: "Secondary field for the category (price, address, author, translation)", schema: string, isOptional: true),
            .init(name: "link", description: "URL or email address if visible", schema: string, isOptional: true),
            .init(name: "extra1", description: "Third field for the category (store, city, genre, language)", schema: string, isOptional: true),
            .init(name: "extra2", description: "Fourth field for the category (currency, country, year, example)", schema: string, isOptional: true),
            .init(name: "notes", description: "Other useful details visible in the screenshot", schema: string, isOptional: true),
        ]
        if allowNewCategory {
            properties.append(
                .init(
                    name: "suggestedCategoryName",
                    description: "Short name for a new category; only when category is \(OnDeviceAnalysisPrompt.newCategoryKey)",
                    schema: string,
                    isOptional: true
                )
            )
        }

        let item = DynamicGenerationSchema(
            name: "CatalogItem",
            description: "One item visible in the screenshot",
            properties: properties
        )
        let items = DynamicGenerationSchema(
            arrayOf: item,
            minimumElements: 0,
            maximumElements: OnDeviceAnalysisPrompt.maxItems
        )
        let root = DynamicGenerationSchema(
            name: "ScreenshotExtraction",
            description: "All items extracted from the screenshot",
            properties: [
                .init(name: "items", description: "Extracted items, one per product, place, book, etc.", schema: items),
            ]
        )
        return try GenerationSchema(root: root, dependencies: [])
    }

    // MARK: Parse

    private static func parseItems(_ content: GeneratedContent) throws -> [[String: String]] {
        let rawItems: [GeneratedContent]
        do {
            rawItems = try content.value([GeneratedContent].self, forProperty: "items")
        } catch {
            let preview = String(content.jsonString.prefix(120))
            throw OnDeviceAnalysisError.decodingFailed("Expected an items array. Got: \(preview)")
        }

        return rawItems.compactMap { item -> [String: String]? in
            func optional(_ key: String) -> String {
                let value = try? item.value(String?.self, forProperty: key)
                return (value ?? nil)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            }
            guard
                let category = try? item.value(String.self, forProperty: "category"),
                !category.isEmpty,
                let title = try? item.value(String.self, forProperty: "title"),
                !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return nil }

            return [
                "category": category,
                "title": title,
                "subtitle": optional("subtitle"),
                "link": optional("link"),
                "extra1": optional("extra1"),
                "extra2": optional("extra2"),
                "notes": optional("notes"),
                "suggestedCategoryName": optional("suggestedCategoryName"),
            ]
        }
    }

    // MARK: Errors

    private static func mapError(_ error: Error) -> OnDeviceAnalysisError {
        if let known = error as? OnDeviceAnalysisError { return known }

        if let modelError = error as? LanguageModelError {
            switch modelError {
            case .contextSizeExceeded:           return .contextSizeExceeded
            case .rateLimited:                   return .rateLimited
            case .guardrailViolation, .refusal:  return .refused
            case .timeout:                       return .timeout
            case .unsupportedLanguageOrLocale:   return .unsupportedLanguage
            case .unsupportedCapability,
                 .unsupportedTranscriptContent:  return .unavailable(.visionNotSupported)
            case .unsupportedGenerationGuide:    return .decodingFailed(modelError.localizedDescription)
            @unknown default:                    return .underlying(error)
            }
        }

        if let generationError = error as? LanguageModelSession.GenerationError {
            switch generationError {
            case .assetsUnavailable:                      return .unavailable(.modelNotReady)
            case .guardrailViolation, .refusal:           return .refused
            case .rateLimited, .concurrentRequests:       return .rateLimited
            case .unsupportedLanguageOrLocale:            return .unsupportedLanguage
            case .decodingFailure, .unsupportedGuide:     return .decodingFailed(generationError.localizedDescription)
            case .exceededContextWindowSize:              return .contextSizeExceeded
            @unknown default:                             return .underlying(error)
            }
        }

        if let systemError = error as? SystemLanguageModel.Error {
            switch systemError {
            case .assetsUnavailable: return .unavailable(.modelNotReady)
            @unknown default:        return .underlying(error)
            }
        }

        return .underlying(error)
    }
}

#endif
