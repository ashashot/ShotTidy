//
//  SafariWebExtensionHandler.swift
//  ShotTidySafariExtension
//
//  Native side of the Safari Web Extension. Receives messages sent from
//  background.js via browser.runtime.sendNativeMessage and routes them:
//
//    getStatus   → Pro flag + custom categories from the App Group
//    analyzeText → analyze-text Edge Function (per-user JWT via
//                  SupabaseAuthManager), returns extracted items
//    saveItems   → appends PendingDraftItems to the App Group inbox and
//                  notifies the running Mac app via DistributedNotificationCenter
//

import SafariServices
import os.log

final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    private static let logger = Logger(subsystem: "com.mbx.ShotTidier.SafariExtension", category: "native-messaging")

    /// Distributed notification the Mac app observes to import the inbox immediately.
    private static let inboxNotificationName = "com.mbx.ShotTidier.extensionInboxUpdated"

    // MARK: - NSExtensionRequestHandling

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem
        let message = request?.userInfo?[SFExtensionMessageKey] as? [String: Any] ?? [:]
        let action = message["action"] as? String ?? ""

        Self.logger.info("Received native message, action: \(action, privacy: .public)")

        switch action {
        case "getStatus":
            Self.reply(context, Self.statusPayload())

        case "analyzeText":
            Task {
                let payload = await Self.analyzeText(message)
                Self.reply(context, payload)
            }

        case "saveItems":
            Self.reply(context, Self.saveItems(message))

        default:
            Self.reply(context, ["ok": false, "error": "Unknown action: \(action)"])
        }
    }

    private static func reply(_ context: NSExtensionContext, _ payload: [String: Any]) {
        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: payload]
        context.completeRequest(returningItems: [response])
    }

    // MARK: - getStatus

    private static func statusPayload() -> [String: Any] {
        let customCategories = AppGroupManager.loadCustomCategories().map {
            ["key": $0.key, "name": $0.name]
        }
        return [
            "ok": true,
            "isPro": AppGroupManager.loadIsProStatus(),
            "customCategories": customCategories,
        ]
    }

    // MARK: - analyzeText

    private static func analyzeText(_ message: [String: Any]) async -> [String: Any] {
        // The Safari extension is a Pro feature: saved items only reach other
        // devices via CloudKit sync, which is Pro-gated.
        guard AppGroupManager.loadIsProStatus() else {
            return [
                "ok": false,
                "code": "pro_required",
                "error": "ShotTidier Pro is required to use the Safari extension.",
            ]
        }

        let text = (message["text"] as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return ["ok": false, "error": "No text selected."]
        }

        guard let url = URL(string: "\(Config.supabaseURL)/functions/v1/analyze-text") else {
            return ["ok": false, "error": "Invalid endpoint URL."]
        }

        var body: [String: Any] = [
            "text": String(text.prefix(20_000)),
            "sourceURL": message["url"] as? String ?? "",
            "pageTitle": message["title"] as? String ?? "",
        ]
        let custom = AppGroupManager.loadCustomCategories()
        if !custom.isEmpty {
            body["customCategories"] = custom.map {
                ["key": $0.key, "name": $0.name, "hint": $0.hint]
            }
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

        let token = await SupabaseAuthManager.shared.bearerToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var data: Data
        var response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            return ["ok": false, "error": "Network error: \(error.localizedDescription)"]
        }

        // Expired session — refresh once and retry.
        if let http = response as? HTTPURLResponse, http.statusCode == 401,
           let fresh = await SupabaseAuthManager.shared.recoverFromAuthFailure() {
            request.setValue("Bearer \(fresh)", forHTTPHeaderField: "Authorization")
            do {
                (data, response) = try await URLSession.shared.data(for: request)
            } catch {
                return ["ok": false, "error": "Network error: \(error.localizedDescription)"]
            }
        }

        if let http = response as? HTTPURLResponse, http.statusCode != 200 {
            let serverMessage = (try? JSONSerialization.jsonObject(with: data) as? [String: Any])
                .flatMap { $0?["error"] as? String }
            if http.statusCode == 429 {
                return [
                    "ok": false,
                    "code": "quota_exceeded",
                    "error": serverMessage ?? "Rate limit exceeded. Please wait a moment.",
                ]
            }
            return ["ok": false, "error": serverMessage ?? "Server error (\(http.statusCode))."]
        }

        // Parse the raw OpenAI payload: choices[0].message.content → { items: [...] }
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let messageDict = choices.first?["message"] as? [String: Any],
            let content = messageDict["content"] as? String,
            let contentData = content.data(using: .utf8),
            let contentJson = try? JSONSerialization.jsonObject(with: contentData) as? [String: Any],
            let rawItems = contentJson["items"] as? [[String: Any]]
        else {
            return ["ok": false, "error": "Could not parse the AI response. Please try again."]
        }

        // Keep only string fields so the payload stays plist-serializable.
        let items: [[String: String]] = rawItems.compactMap { dict in
            guard
                let category = dict["category"] as? String, !category.isEmpty,
                let title = dict["title"] as? String,
                !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { return nil }
            return [
                "category": category,
                "title": title,
                "subtitle": dict["subtitle"] as? String ?? "",
                "link": dict["link"] as? String ?? "",
                "extra1": dict["extra1"] as? String ?? "",
                "extra2": dict["extra2"] as? String ?? "",
                "notes": dict["notes"] as? String ?? "",
            ]
        }

        return ["ok": true, "items": items]
    }

    // MARK: - saveItems

    private static func saveItems(_ message: [String: Any]) -> [String: Any] {
        let rawItems = message["items"] as? [[String: Any]] ?? []
        guard !rawItems.isEmpty else {
            return ["ok": false, "error": "Nothing to save."]
        }

        var drafts = AppGroupManager.loadPendingDrafts()
        var saved = 0
        for dict in rawItems {
            guard
                let category = dict["category"] as? String, !category.isEmpty,
                let title = dict["title"] as? String,
                !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else { continue }
            drafts.append(PendingDraftItem(
                categoryKey: category,
                title: title,
                subtitle: dict["subtitle"] as? String ?? "",
                link: dict["link"] as? String ?? "",
                extra1: dict["extra1"] as? String ?? "",
                extra2: dict["extra2"] as? String ?? "",
                notes: dict["notes"] as? String ?? ""
            ))
            saved += 1
        }

        guard saved > 0 else {
            return ["ok": false, "error": "Nothing to save."]
        }

        do {
            try AppGroupManager.savePendingDrafts(drafts)
        } catch {
            return ["ok": false, "error": "Failed to save: \(error.localizedDescription)"]
        }

        // Wake the running Mac app so the items appear immediately.
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(inboxNotificationName),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )

        return ["ok": true, "saved": saved]
    }
}
