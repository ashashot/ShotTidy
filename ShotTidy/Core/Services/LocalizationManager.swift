//
//  LocalizationManager.swift
//  ShotTidy
//
//  In-app language override. Persisted to the shared App Group so the
//  Share Extension and Widget can read the same choice.
//

import SwiftUI

// MARK: - AppLanguage

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case en, zhHans, es, ptBR, ptPT, tr, ru, it, de, fr, ja, ko, hy

    var id: String { rawValue }

    init(storageValue: String?) {
        guard
            let storageValue,
            let match = AppLanguage.allCases.first(where: { $0.localeIdentifier == storageValue })
        else {
            self = .system
            return
        }
        self = match
    }

    /// Value persisted to `AppGroupManager`; `nil` means "follow system language".
    var storageValue: String? {
        self == .system ? nil : localeIdentifier
    }

    /// `nil` for `.system` — callers should fall back to `Locale.autoupdatingCurrent`.
    var locale: Locale? {
        self == .system ? nil : Locale(identifier: localeIdentifier)
    }

    private var localeIdentifier: String {
        switch self {
        case .system: return ""
        case .en:     return "en"
        case .zhHans: return "zh-Hans"
        case .es:     return "es"
        case .ptBR:   return "pt-BR"
        case .ptPT:   return "pt-PT"
        case .tr:     return "tr"
        case .ru:     return "ru"
        case .it:     return "it"
        case .de:     return "de"
        case .fr:     return "fr"
        case .ja:     return "ja"
        case .ko:     return "ko"
        case .hy:     return "hy"
        }
    }

    /// Shown in the Settings picker — always in the language's own name,
    /// regardless of the currently active UI language.
    var displayName: String {
        switch self {
        case .system: return String(localized: "System Default", bundle: AppLocale.bundle)
        case .en:     return "English"
        case .zhHans: return "中文（简体）"
        case .es:     return "Español"
        case .ptBR:   return "Português (Brasil)"
        case .ptPT:   return "Português (Portugal)"
        case .tr:     return "Türkçe"
        case .ru:     return "Русский"
        case .it:     return "Italiano"
        case .de:     return "Deutsch"
        case .fr:     return "Français"
        case .ja:     return "日本語"
        case .ko:     return "한국어"
        case .hy:     return "Հայերեն"
        }
    }
}

// MARK: - LocalizationManager

@Observable
final class LocalizationManager {

    var selectedLanguage: AppLanguage {
        didSet { AppGroupManager.saveLanguageOverride(selectedLanguage.storageValue) }
    }

    init() {
        selectedLanguage = AppLanguage(storageValue: AppGroupManager.loadLanguageOverride())
    }

    /// Locale to inject via `.environment(\.locale, ...)` at the app root.
    var resolvedLocale: Locale {
        selectedLanguage.locale ?? .autoupdatingCurrent
    }
}
