//
//  Config.swift
//  ShotTidy
//
//  Ключ читается из Info.plist, куда Xcode подставляет значение
//  из Secrets.xcconfig (который НЕ попадает в git).
//

import Foundation

enum Config {
    static let openAIKey: String = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
              !key.isEmpty,
              key != "your_openai_api_key_here" else {
            assertionFailure("⚠️ OPENAI_API_KEY не настроен. Создай Secrets.xcconfig из Secrets.xcconfig.example")
            return ""
        }
        return key
    }()
}
