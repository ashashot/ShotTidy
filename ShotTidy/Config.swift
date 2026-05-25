//
//  Config.swift
//  ShotTidy
//
//  The key is read from Info.plist, where Xcode substitutes the value
//  from Secrets.xcconfig (which is NOT committed to git).
//

import Foundation

enum Config {
    static let openAIKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
              !key.isEmpty,
              key != "your_openai_api_key_here" else {
            assertionFailure("⚠️ OPENAI_API_KEY is not configured. Create Secrets.xcconfig from Secrets.xcconfig.example")
            return ""
        }
        return key
    }()
}
