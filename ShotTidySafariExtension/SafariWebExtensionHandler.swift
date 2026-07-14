//
//  SafariWebExtensionHandler.swift
//  ShotTidySafariExtension
//
//  Native side of the Safari Web Extension. Receives messages sent from
//  background.js via browser.runtime.sendNativeMessage.
//
//  Spike scope: echo the payload back so the JS ⇄ native roundtrip can be
//  verified end-to-end. The real implementation will route "saveItems" /
//  "getStatus" actions to the App Group inbox and Pro status.
//

import SafariServices
import os.log

final class SafariWebExtensionHandler: NSObject, NSExtensionRequestHandling {

    private let logger = Logger(subsystem: "com.mbx.ShotTidier.SafariExtension", category: "native-messaging")

    func beginRequest(with context: NSExtensionContext) {
        let request = context.inputItems.first as? NSExtensionItem
        let message = request?.userInfo?[SFExtensionMessageKey] as? [String: Any] ?? [:]
        let action = message["action"] as? String ?? "unknown"

        logger.info("Received native message, action: \(action, privacy: .public)")

        let response = NSExtensionItem()
        response.userInfo = [SFExtensionMessageKey: [
            "ok": true,
            "action": action,
            "receivedTextLength": (message["text"] as? String)?.count ?? 0,
            "handler": "ShotTidySafariExtension stub",
        ]]
        context.completeRequest(returningItems: [response])
    }
}
