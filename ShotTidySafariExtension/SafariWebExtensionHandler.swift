//
//  SafariWebExtensionHandler.swift
//  ShotTidySafariExtension
//
//  Native side of the Safari Web Extension. Receives messages sent from
//  background.js via browser.runtime.sendNativeMessage and routes them:
//
//    getStatus   → Pro flag + custom categories + analysis engine
//    analyzeText → on-device Foundation Models (the Mac app is on-device
//                  only; a Mac without Apple Intelligence gets an error);
//                  returns extracted items
//    saveItems   → appends PendingDraftItems to the App Group inbox and
//                  notifies the running Mac app via DistributedNotificationCenter
//

import SafariServices
import os.log

final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    private static let logger = Logger(subsystem: "com.mbx.ShotTidier.SafariExtension", category: "native-messaging")

    /// Distributed notification the Mac app observes to import the inbox immediately.
    /// Sandboxed processes may only post distributed notifications whose name is
    /// prefixed with an application-group identifier they belong to.
    private static let inboxNotificationName = "group.com.mbx.ShotTidier.extensionInboxUpdated"

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
        // Built-ins come from the Swift source of truth so the panel's
        // category list never drifts from ItemCategory.
        let builtinCategories = ItemCategory.allCases.map {
            ["key": $0.rawValue, "name": $0.localizedName]
        }
        let customCategories = AppGroupManager.loadCustomCategories().map {
            ["key": $0.key, "name": $0.name]
        }
        return [
            "ok": true,
            "isPro": AppGroupManager.loadIsProStatus(),
            "builtinCategories": builtinCategories,
            "customCategories": customCategories,
            "analysisEngine": AnalysisEngineResolver.resolve().engine?.rawValue ?? "unsupported",
        ]
    }

    /// Error payload for a Mac that cannot run the on-device model.
    private static func unsupportedPayload(_ availability: OnDeviceAnalysisAvailability) -> [String: Any] {
        [
            "ok": false,
            "code": "unsupported_device",
            "error": "ShotTidier requires Apple Intelligence on this Mac. \(availability.localizedDescription)",
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

        // The Mac app is on-device only — no cloud path on this platform.
        guard case .onDevice = AnalysisEngineResolver.resolve() else {
            return unsupportedPayload(OnDeviceAnalysisEngine.availability)
        }
        return await analyzeTextOnDevice(text, message: message)
    }

    /// Apple's on-device model — nothing leaves the Mac.
    private static func analyzeTextOnDevice(_ text: String, message: [String: Any]) async -> [String: Any] {
        let hints = AppGroupManager.loadCustomCategories().map {
            AnalysisCategoryHint(key: $0.key, name: $0.name, hint: $0.hint)
        }
        do {
            let items = try await OnDeviceAnalysisEngine.shared.analyze(
                text: text,
                sourceURL: message["url"] as? String ?? "",
                pageTitle: message["title"] as? String ?? "",
                customCategories: hints,
                allowNewCategory: false   // the panel has no UI to create a category
            )
            return ["ok": true, "items": items, "engine": AnalysisEngine.onDevice.rawValue]
        } catch let error as OnDeviceAnalysisError {
            if case .unavailable(let availability) = error {
                // Model went away between the check and the call.
                return unsupportedPayload(availability)
            }
            return ["ok": false, "error": error.localizedDescription]
        } catch {
            return ["ok": false, "error": error.localizedDescription]
        }
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
