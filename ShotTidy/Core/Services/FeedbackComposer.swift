//
//  FeedbackComposer.swift
//  ShotTidy
//
//  "Send Feedback" support: builds a mailto: link pre-filled with the support
//  address, subject and diagnostic info, opened in the user's default Mail app.
//
//  Note: MFMailComposeViewController is intentionally avoided — its
//  canSendMail()/presentation path crashes on iOS 17/18 Simulators with
//  "-[OS_dispatch_mach_msg _setContext:]: unrecognized selector" (a known
//  Simulator-only MailCompositionService bug). mailto: is simpler and reliable
//  on both Simulator and device.
//

import Foundation
import UIKit

enum FeedbackComposer {

    static var subject: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        return "ShotTidier Feedback (v\(version))"
    }

    /// Diagnostic footer appended to the feedback email so issues are easier to triage.
    static func diagnosticsBody(isPro: Bool) -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build   = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        let device  = UIDevice.current
        let plan    = isPro ? "Pro" : "Free"

        return """


        ---
        ShotTidier v\(version) (\(build))
        Plan: \(plan)
        \(device.systemName) \(device.systemVersion), \(device.model)
        """
    }

    /// `mailto:` URL pre-filled with the support address, subject and diagnostics.
    static func feedbackMailURL(isPro: Bool) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Config.feedbackEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: diagnosticsBody(isPro: isPro))
        ]
        return components.url
    }
}
