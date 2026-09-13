//
//  OnDeviceAnalysisEngine.swift
//  ShotTidy
//
//  Screenshot analysis with Apple's on-device Foundation Models. Two modes,
//  both fully on the device — nothing is uploaded:
//
//  • Image mode (iOS 27+): the system model reads the screenshot itself via
//    an image attachment. Best on-device quality.
//  • Text mode (iOS 26): the iOS 26 model is text-only, so Vision OCR first
//    recognizes the text on the screenshot and the model structures that text.
//    Layout and pictures are lost, so results are noticeably weaker.
//  • Plain text (any OS with the model): `analyze(text:...)` structures text
//    the caller already has — the Safari extension's page selection. Works in
//    both image and text availability states, no OCR involved.
//
//  Output mirrors the cloud path (`SupabaseFunctionClient.openAIItems`): an
//  array of string dictionaries with the same keys, so callers map them into
//  `DraftItem` / `PendingDraftItem` exactly like the GPT-4o response.
//
//  Cross-compiled into the Share Extension and the macOS app.
//  Foundation + FoundationModels + Vision only — no UIKit/AppKit.
//
//  Build note: the image-attachment API exists only in the iOS 27 SDK
//  (Xcode 27 / Swift 6.4). With an older toolchain the image mode is compiled
//  out and iOS 27 devices get text mode — see `availability`.
//

import Foundation
import CoreGraphics
import ImageIO
import Vision
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Availability

nonisolated enum OnDeviceAnalysisAvailability: Equatable, Sendable {

    /// Why only the OCR-based text mode is available.
    nonisolated enum TextOnlyReason: Equatable, Sendable {
        /// Device runs iOS/macOS 26 — the system model cannot take images there.
        case osVersion
        /// Device runs iOS/macOS 27+, but this binary was built with a pre-27 SDK.
        case build
        /// iOS 27+ model reports no vision capability on this device.
        case modelWithoutVision
    }

    /// Full image analysis (iOS 27+).
    case available
    /// Model is usable, but only from OCR text (see reason).
    case availableTextOnly(TextOnlyReason)
    /// OS older than iOS/macOS 26 — no system model at all.
    case requiresNewerOS
    case deviceNotEligible
    case appleIntelligenceNotEnabled
    /// Model assets are still downloading or otherwise not ready.
    case modelNotReady

    /// True for both image and text modes.
    var isAvailable: Bool {
        switch self {
        case .available, .availableTextOnly: return true
        default: return false
        }
    }

    var isTextOnly: Bool {
        if case .availableTextOnly = self { return true }
        return false
    }

    /// Human-readable status for Settings and fallback notices.
    var localizedDescription: String {
        switch self {
        case .available:
            return String(localized: "On-device analysis is ready.", bundle: AppLocale.bundle)
        case .availableTextOnly(.osVersion):
            return String(localized: "Analyzes text recognized in the screenshot. Full image analysis requires iOS 27.", bundle: AppLocale.bundle)
        case .availableTextOnly(.build):
            return String(localized: "Analyzes text recognized in the screenshot. This build was made without full image analysis; rebuild with Xcode 27.", bundle: AppLocale.bundle)
        case .availableTextOnly(.modelWithoutVision):
            return String(localized: "Analyzes text recognized in the screenshot. The model on this device cannot read images.", bundle: AppLocale.bundle)
        case .requiresNewerOS:
            return String(localized: "Requires iOS 26 or later.", bundle: AppLocale.bundle)
        case .deviceNotEligible:
            return String(localized: "This device does not support Apple Intelligence.", bundle: AppLocale.bundle)
        case .appleIntelligenceNotEnabled:
            return String(localized: "Turn on Apple Intelligence in Settings to use the on-device model.", bundle: AppLocale.bundle)
        case .modelNotReady:
            return String(localized: "The on-device model is still downloading. Try again later.", bundle: AppLocale.bundle)
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
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            #if compiler(>=6.4)
            if #available(iOS 27.0, macOS 27.0, *) {
                return ImageModeBridge.availability
            }
            #endif
            let base = TextModeBridge.modelAvailability
            guard base == .available else { return base }
            if #available(iOS 27.0, macOS 27.0, *) {
                return .availableTextOnly(.build)
            }
            return .availableTextOnly(.osVersion)
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
        let current = Self.availability
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            switch current {
            case .available:
                #if compiler(>=6.4)
                if #available(iOS 27.0, macOS 27.0, *) {
                    return try await ImageModeBridge.analyze(
                        cgImage: cgImage,
                        orientation: orientation,
                        customCategories: customCategories,
                        allowNewCategory: allowNewCategory
                    )
                }
                #endif
                throw OnDeviceAnalysisError.unavailable(current)
            case .availableTextOnly:
                return try await TextModeBridge.analyze(
                    cgImage: cgImage,
                    orientation: orientation,
                    customCategories: customCategories,
                    allowNewCategory: allowNewCategory
                )
            default:
                throw OnDeviceAnalysisError.unavailable(current)
            }
        }
        #endif
        throw OnDeviceAnalysisError.unavailable(current)
    }
}

extension OnDeviceAnalysisEngine {

    /// Structures text the caller already has (e.g. a web page selection).
    /// Mirrors the `analyze-text` Edge Function: `sourceURL` / `pageTitle`
    /// let the model link items to the page they came from.
    func analyze(
        text: String,
        sourceURL: String,
        pageTitle: String,
        customCategories: [AnalysisCategoryHint],
        allowNewCategory: Bool
    ) async throws -> [[String: String]] {
        let current = Self.availability
        guard current.isAvailable else { throw OnDeviceAnalysisError.unavailable(current) }
        #if canImport(FoundationModels)
        if #available(iOS 26.0, macOS 26.0, *) {
            return try await TextModeBridge.analyze(
                text: text,
                sourceURL: sourceURL,
                pageTitle: pageTitle,
                customCategories: customCategories,
                allowNewCategory: allowNewCategory
            )
        }
        #endif
        throw OnDeviceAnalysisError.unavailable(current)
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

    /// Text mode gets a tighter cap: the text-only model tends to pad the
    /// list with duplicates when it is allowed to go long.
    static let maxItemsTextMode = 10

    /// Custom categories beyond this are ignored to protect the token budget.
    static let maxCustomCategories = 30

    /// OCR text beyond this is truncated so instructions + schema + text +
    /// answer stay inside the on-device context window.
    static let maxRecognizedTextCharacters = 3500

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
    - Add each distinct product, place, book, etc. as a separate item. Never list the same item twice.
    - Copy names, prices, addresses and URLs exactly as shown. DO NOT invent details that are not visible.
    - DO NOT make up URLs, store names, currencies or dates. Leave a field out when the screenshot does not show it.
    - Pick the single best category key for every item.
    - App settings, menus, buttons, navigation bars, keyboards and other UI chrome are NOT items. \
    If the screenshot contains nothing worth saving, return an empty items list.

    Examples of correct field mapping:
    - "Nike Air Zoom Pegasus 41 / Men's Road Running Shoes / $139.99" → \
    category shopping, title "Nike Air Zoom Pegasus 41", subtitle "$139.99", extra1 "Nike", extra2 "USD", notes "Men's Road Running Shoes"
    - "Project Hail Mary / by Andy Weir / Science Fiction · 2021" → \
    category books, title "Project Hail Mary", subtitle "Andy Weir", extra1 "Science Fiction", extra2 "2021"
    """

    /// Instructions for the OCR-based text mode (iOS 26): same rules, but the
    /// model gets recognized text instead of the picture.
    static let textModeInstructions = instructions + """


    The user provides the text recognized from the screenshot by OCR instead of the picture. \
    Layout is lost and there may be recognition mistakes: decide which lines belong to the same item, \
    ignore navigation labels, buttons and timestamps, and never treat OCR noise as an item. \
    Every value you output must be copied from the provided text — if it is not in the text, leave the field out.
    """

    /// Per-request prompt. Custom categories are user data, so they belong
    /// here rather than in the instructions.
    static func userPrompt(customCategories: [AnalysisCategoryHint], allowNewCategory: Bool) -> String {
        var text = "Extract the items from the attached screenshot."
        text += customCategoriesSection(customCategories)
        text += newCategorySection(allowNewCategory)
        return text
    }

    /// Instructions for text the user selected on a web page (Safari extension).
    static let webTextInstructions = instructions + """


    The user provides text selected on a web page instead of a screenshot, plus the site and page title. \
    Every value you output must be copied from the provided text — if it is not there, leave the field out.
    """

    /// Prompt for a web page selection: page context, the text, category guidance.
    /// Only the host of the page URL goes in — a full path like
    /// "/science/2026/09/ocean-noise/" trips the model's language detector
    /// ("Unsupported language"). The page link is attached in code afterwards.
    static func webTextPrompt(
        text: String,
        sourceHost: String,
        pageTitle: String,
        customCategories: [AnalysisCategoryHint],
        allowNewCategory: Bool
    ) -> String {
        var prompt = ""
        if !sourceHost.isEmpty || !pageTitle.isEmpty {
            prompt += "The text was selected on a web page"
            if !sourceHost.isEmpty { prompt += " on \(sourceHost)" }
            if !pageTitle.isEmpty { prompt += " titled \"\(pageTitle)\"" }
            prompt += ".\n\n"
        }
        prompt += "Selected text:\n\n\(text)\n\nExtract the items from this text."
        prompt += customCategoriesSection(customCategories)
        prompt += newCategorySection(allowNewCategory)
        return prompt
    }

    /// Text-mode prompt: recognized text followed by the same category guidance.
    static func textModePrompt(
        recognizedText: String,
        customCategories: [AnalysisCategoryHint],
        allowNewCategory: Bool
    ) -> String {
        var text = "Recognized text from the screenshot:\n\n\(recognizedText)\n\nExtract the items from this text."
        text += customCategoriesSection(customCategories)
        text += newCategorySection(allowNewCategory)
        return text
    }

    private static func customCategoriesSection(_ customCategories: [AnalysisCategoryHint]) -> String {
        let custom = Array(customCategories.prefix(maxCustomCategories))
        guard !custom.isEmpty else { return "" }
        let lines = custom.map { category -> String in
            let hint = category.hint.trimmingCharacters(in: .whitespacesAndNewlines)
            let suffix = hint.isEmpty ? "" : " — \(hint)"
            return "- \"\(category.key)\" (user category \"\(category.name)\")\(suffix)"
        }
        return "\n\nThe user also defined these custom categories. Prefer them whenever an item fits:\n"
            + lines.joined(separator: "\n")
    }

    private static func newCategorySection(_ allowNewCategory: Bool) -> String {
        guard allowNewCategory else { return "" }
        return """


        If an item does NOT fit any category, use the category "\(newCategoryKey)" and set \
        suggestedCategoryName to a short, human-readable name for a new category (e.g. "Wines", "Gym Workouts"). \
        Group similar items under the same suggested name. Only do this when nothing else is a reasonable fit.
        """
    }

    /// Every category key the model may emit for this request.
    static func allowedCategoryKeys(customCategories: [AnalysisCategoryHint], allowNewCategory: Bool) -> [String] {
        var keys = builtInCategoryKeys
        keys += customCategories.prefix(maxCustomCategories).map(\.key)
        if allowNewCategory { keys.append(newCategoryKey) }
        return keys
    }
}

// MARK: - OCR (Vision, on device)

enum OnDeviceTextRecognizer {

    /// Recognizes the text on a screenshot, top to bottom, one line per row.
    /// Returns an empty string when nothing readable is found.
    static func recognizeText(
        cgImage: CGImage,
        orientation: CGImagePropertyOrientation
    ) async throws -> String {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true

        let observations = try await request.perform(on: cgImage, orientation: orientation)
        let lines = observations.compactMap { observation -> String? in
            let line = observation.topCandidates(1).first?.string
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return line.isEmpty ? nil : line
        }
        let text = lines.joined(separator: "\n")
        if text.count > OnDeviceAnalysisPrompt.maxRecognizedTextCharacters {
            return String(text.prefix(OnDeviceAnalysisPrompt.maxRecognizedTextCharacters))
        }
        return text
    }
}

// MARK: - Grounding (text mode)

/// Filters model output against the OCR text it was derived from. Keeps only
/// items whose title occurs in the text, clears links/subtitles/multi-word
/// extras that do not occur there, and leaves short single-word extras alone
/// (currency, language, genre, priority are legitimate inferences).
///
/// "Occurs" is token-based and forgiving: at least 60% of a value's words
/// (2+ characters, letters/digits only) must appear in the text, so "$190.00"
/// reformatted as "190.00 USD" survives while an invented address does not.
enum OnDeviceResultGrounding {

    static func ground(_ items: [[String: String]], in recognizedText: String) -> [[String: String]] {
        let haystack = tokens(of: recognizedText)
        guard !haystack.isEmpty else { return [] }

        return items.compactMap { item in
            guard let title = item["title"], occurs(title, in: haystack) else { return nil }
            var grounded = item
            for key in ["link", "subtitle"] {
                if let value = grounded[key], !value.isEmpty, !occurs(value, in: haystack) {
                    grounded[key] = ""
                }
            }
            for key in ["extra1", "extra2"] {
                if let value = grounded[key], !value.isEmpty, !isSingleWord(value), !occurs(value, in: haystack) {
                    grounded[key] = ""
                }
            }
            return grounded
        }
    }

    /// Clears links that do not occur in the OCR text; keeps everything else.
    /// Used in image mode, where titles may legitimately come from pictures
    /// and logos but a URL still has to be readable text.
    static func groundLinks(_ items: [[String: String]], in recognizedText: String) -> [[String: String]] {
        let haystack = tokens(of: recognizedText)
        return items.map { item in
            var grounded = item
            if let link = grounded["link"], !link.isEmpty, !occurs(link, in: haystack) {
                grounded["link"] = ""
            }
            return grounded
        }
    }

    /// Built-in categories whose schema has no link field.
    private static let linklessCategories: Set<String> = ["languageLearning", "prompts", "health", "tasks"]

    /// Gives items that are "the page itself" the page URL as their link — the
    /// only item on the page, or one whose title overlaps the page title. The
    /// cloud prompt asks the model to do this; the on-device model never sees
    /// the full URL, so it is done here.
    static func attachPageLink(_ sourceURL: String, to items: [[String: String]], pageTitle: String) -> [[String: String]] {
        guard !sourceURL.isEmpty else { return items }
        let titleTokens = tokens(of: pageTitle)
        return items.map { item in
            var linked = item
            guard (linked["link"] ?? "").isEmpty,
                  !linklessCategories.contains(linked["category"] ?? "")
            else { return linked }
            let isWholePage = items.count == 1
            let matchesTitle: Bool = {
                let words = tokens(of: linked["title"] ?? "")
                guard !words.isEmpty, !titleTokens.isEmpty else { return false }
                return Double(words.intersection(titleTokens).count) / Double(words.count) >= 0.5
            }()
            if isWholePage || matchesTitle { linked["link"] = sourceURL }
            return linked
        }
    }

    /// True when the text has anything that could be a URL or email address.
    static func containsLinkLikeText(_ text: String) -> Bool {
        let lower = text.lowercased()
        if lower.contains("http") || lower.contains("www.") || lower.contains("@") { return true }
        // Bare domains such as "amazon.com/s?k=..." or "goodreads.com".
        return lower.range(of: #"[a-z0-9-]+\.(com|net|org|io|app|co|ru|de|fr|es|it|uk|br|pt|tr|jp|kr|am|me|ly|ai)\b"#, options: .regularExpression) != nil
    }

    /// Lowercased, whitespace collapsed to single spaces, trimmed.
    static func normalize(_ text: String) -> String {
        text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Lowercased alphanumeric words of 2+ characters.
    static func tokens(of text: String) -> Set<String> {
        Set(
            text.lowercased()
                .components(separatedBy: CharacterSet.alphanumerics.inverted)
                .filter { $0.count >= 2 }
        )
    }

    private static func occurs(_ value: String, in haystack: Set<String>) -> Bool {
        let words = tokens(of: value)
        // Nothing to check (e.g. "$5") — do not punish the model for brevity.
        guard !words.isEmpty else { return true }
        let hits = words.filter { haystack.contains($0) }.count
        return Double(hits) / Double(words.count) >= 0.6
    }

    private static func isSingleWord(_ value: String) -> Bool {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
            .rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
}

#if canImport(FoundationModels)

// MARK: - Shared Foundation Models plumbing (iOS 26+)

@available(iOS 26.0, macOS 26.0, *)
private enum FoundationModelsSupport {

    static var modelAvailability: OnDeviceAnalysisAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible:           return .deviceNotEligible
            case .appleIntelligenceNotEnabled: return .appleIntelligenceNotEnabled
            case .modelNotReady:               return .modelNotReady
            @unknown default:                  return .deviceNotEligible
            }
        }
    }

    /// Runs one stateless session with the given instructions and prompt and
    /// parses the structured answer. Errors are returned raw for the caller to map.
    static func run(
        instructions: String,
        prompt: Prompt,
        customCategories: [AnalysisCategoryHint],
        allowNewCategory: Bool,
        allowLink: Bool,
        maximumResponseTokens: Int,
        maxItems: Int = OnDeviceAnalysisPrompt.maxItems
    ) async throws -> [[String: String]] {
        let keys = OnDeviceAnalysisPrompt.allowedCategoryKeys(
            customCategories: customCategories, allowNewCategory: allowNewCategory
        )
        let schema: GenerationSchema
        do {
            schema = try makeSchema(
                categoryKeys: keys, allowNewCategory: allowNewCategory, allowLink: allowLink, maxItems: maxItems
            )
        } catch {
            throw OnDeviceAnalysisError.decodingFailed("Schema: \(error.localizedDescription)")
        }

        // One stateless session per screenshot — there is no conversation to keep.
        let session = LanguageModelSession(model: SystemLanguageModel.default, instructions: instructions)
        let response = try await session.respond(
            to: prompt,
            schema: schema,
            includeSchemaInPrompt: true,
            options: options(maximumResponseTokens: maximumResponseTokens)
        )
        return try parseItems(response.content)
    }

    /// Deterministic decoding: extraction should not be creative.
    private static func options(maximumResponseTokens: Int) -> GenerationOptions {
        #if compiler(>=6.4)
        return GenerationOptions(samplingMode: .greedy, temperature: nil, maximumResponseTokens: maximumResponseTokens)
        #else
        return GenerationOptions(sampling: .greedy, temperature: nil, maximumResponseTokens: maximumResponseTokens)
        #endif
    }

    // MARK: Schema

    /// Builds the response schema at runtime so `category` is constrained to
    /// the exact set of keys valid for this user (built-in + custom + "__new__").
    /// `allowLink` is false when the screenshot text contains nothing URL-like:
    /// without it the small model invents endless Maps/store URLs, which can
    /// even overrun the response budget and break the JSON.
    private static func makeSchema(
        categoryKeys: [String], allowNewCategory: Bool, allowLink: Bool, maxItems: Int
    ) throws -> GenerationSchema {
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
        ]
        if allowLink {
            properties.append(
                .init(name: "link", description: "A URL or email address that literally appears in the screenshot; never guessed", schema: string, isOptional: true)
            )
        }
        properties += [
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
            maximumElements: maxItems
        )
        let root = DynamicGenerationSchema(
            name: "ScreenshotExtraction",
            description: "All items extracted from the screenshot",
            properties: [
                .init(name: "items", description: "Extracted items, one per product, place, book, etc. Empty when nothing worth saving is present.", schema: items),
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

        var seen = Set<String>()
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

            // The small model sometimes pads the list with repeats of one item.
            let identity = category + "\u{1F}" + OnDeviceResultGrounding.normalize(title)
            guard seen.insert(identity).inserted else { return nil }

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

    // MARK: Errors (iOS 26 API surface)

    static func mapError(_ error: Error) -> OnDeviceAnalysisError {
        if let known = error as? OnDeviceAnalysisError { return known }

        if let generationError = error as? LanguageModelSession.GenerationError {
            switch generationError {
            case .assetsUnavailable:                      return .unavailable(.modelNotReady)
            case .guardrailViolation, .refusal:           return .refused
            case .rateLimited, .concurrentRequests:       return .rateLimited
            case .unsupportedLanguageOrLocale:            return .unsupportedLanguage
            case .decodingFailure(let context):           return .decodingFailed(String(context.debugDescription.prefix(400)))
            case .unsupportedGuide(let context):          return .decodingFailed(String(context.debugDescription.prefix(400)))
            case .exceededContextWindowSize:              return .contextSizeExceeded
            @unknown default:                             return .underlying(error)
            }
        }

        return .underlying(error)
    }
}

// MARK: - Text mode (iOS 26+: Vision OCR → text-only model)

@available(iOS 26.0, macOS 26.0, *)
private enum TextModeBridge {

    static var modelAvailability: OnDeviceAnalysisAvailability {
        FoundationModelsSupport.modelAvailability
    }

    static func analyze(
        cgImage: CGImage,
        orientation: CGImagePropertyOrientation,
        customCategories: [AnalysisCategoryHint],
        allowNewCategory: Bool
    ) async throws -> [[String: String]] {
        let recognized: String
        do {
            recognized = try await OnDeviceTextRecognizer.recognizeText(cgImage: cgImage, orientation: orientation)
        } catch {
            throw OnDeviceAnalysisError.invalidImage
        }
        // Nothing readable — not an error, simply no items to extract.
        guard !recognized.isEmpty else { return [] }

        let prompt = OnDeviceAnalysisPrompt.textModePrompt(
            recognizedText: recognized,
            customCategories: customCategories,
            allowNewCategory: allowNewCategory
        )
        return try await structure(
            instructions: OnDeviceAnalysisPrompt.textModeInstructions,
            prompt: prompt,
            groundingText: recognized,
            allowLink: OnDeviceResultGrounding.containsLinkLikeText(recognized),
            customCategories: customCategories,
            allowNewCategory: allowNewCategory
        )
    }

    /// Web page selection (Safari extension): no OCR, the text is given.
    static func analyze(
        text: String,
        sourceURL: String,
        pageTitle: String,
        customCategories: [AnalysisCategoryHint],
        allowNewCategory: Bool
    ) async throws -> [[String: String]] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let clipped = String(trimmed.prefix(OnDeviceAnalysisPrompt.maxRecognizedTextCharacters))

        let host = URL(string: sourceURL)?.host ?? ""
        let prompt = OnDeviceAnalysisPrompt.webTextPrompt(
            text: clipped,
            sourceHost: host,
            pageTitle: pageTitle,
            customCategories: customCategories,
            allowNewCategory: allowNewCategory
        )
        let items = try await structure(
            instructions: OnDeviceAnalysisPrompt.webTextInstructions,
            prompt: prompt,
            groundingText: [clipped, pageTitle].joined(separator: "\n"),
            allowLink: OnDeviceResultGrounding.containsLinkLikeText(clipped),
            customCategories: customCategories,
            allowNewCategory: allowNewCategory
        )
        return OnDeviceResultGrounding.attachPageLink(sourceURL, to: items, pageTitle: pageTitle)
    }

    /// Runs the text-only model and grounds the answer in the source text:
    /// everything the model knows came from that text, so anything not found
    /// there was invented — drop it.
    private static func structure(
        instructions: String,
        prompt: String,
        groundingText: String,
        allowLink: Bool,
        customCategories: [AnalysisCategoryHint],
        allowNewCategory: Bool
    ) async throws -> [[String: String]] {
        let items: [[String: String]]
        do {
            items = try await FoundationModelsSupport.run(
                instructions: instructions,
                prompt: Prompt(prompt),
                customCategories: customCategories,
                allowNewCategory: allowNewCategory,
                allowLink: allowLink,
                maximumResponseTokens: 1200,
                maxItems: OnDeviceAnalysisPrompt.maxItemsTextMode
            )
        } catch {
            throw FoundationModelsSupport.mapError(error)
        }
        return OnDeviceResultGrounding.ground(items, in: groundingText)
    }
}

// MARK: - Image mode (iOS 27 SDK only)

#if compiler(>=6.4)

@available(iOS 27.0, macOS 27.0, *)
private enum ImageModeBridge {

    static var availability: OnDeviceAnalysisAvailability {
        let base = FoundationModelsSupport.modelAvailability
        guard base == .available else { return base }
        return SystemLanguageModel.default.capabilities.contains(.vision)
            ? .available
            : .availableTextOnly(.modelWithoutVision)
    }

    static func analyze(
        cgImage: CGImage,
        orientation: CGImagePropertyOrientation,
        customCategories: [AnalysisCategoryHint],
        allowNewCategory: Bool
    ) async throws -> [[String: String]] {
        // OCR runs here too, only to keep links honest: a URL must be readable
        // text on the screenshot. If OCR fails we just skip that safeguard.
        let recognized = (try? await OnDeviceTextRecognizer.recognizeText(cgImage: cgImage, orientation: orientation)) ?? ""
        let allowLink = recognized.isEmpty || OnDeviceResultGrounding.containsLinkLikeText(recognized)

        let prompt = Prompt {
            Attachment(cgImage, orientation: orientation)
            OnDeviceAnalysisPrompt.userPrompt(
                customCategories: customCategories, allowNewCategory: allowNewCategory
            )
        }
        let items: [[String: String]]
        do {
            items = try await FoundationModelsSupport.run(
                instructions: OnDeviceAnalysisPrompt.instructions,
                prompt: prompt,
                customCategories: customCategories,
                allowNewCategory: allowNewCategory,
                allowLink: allowLink,
                maximumResponseTokens: 1500
            )
        } catch {
            throw mapError(error)
        }
        return recognized.isEmpty ? items : OnDeviceResultGrounding.groundLinks(items, in: recognized)
    }

    /// iOS 27 adds `LanguageModelError`; everything else goes through the shared mapper.
    private static func mapError(_ error: Error) -> OnDeviceAnalysisError {
        if let modelError = error as? LanguageModelError {
            switch modelError {
            case .contextSizeExceeded:           return .contextSizeExceeded
            case .rateLimited:                   return .rateLimited
            case .guardrailViolation, .refusal:  return .refused
            case .timeout:                       return .timeout
            case .unsupportedLanguageOrLocale:   return .unsupportedLanguage
            case .unsupportedCapability,
                 .unsupportedTranscriptContent:  return .unavailable(.availableTextOnly(.modelWithoutVision))
            case .unsupportedGenerationGuide:    return .decodingFailed(modelError.localizedDescription)
            @unknown default:                    return .underlying(error)
            }
        }
        if let systemError = error as? SystemLanguageModel.Error {
            switch systemError {
            case .assetsUnavailable: return .unavailable(.modelNotReady)
            @unknown default:        return .underlying(error)
            }
        }
        return FoundationModelsSupport.mapError(error)
    }
}

#endif
#endif
