//
//  AppLocale.swift
//  ShotTidy
//
//  Resolves the active locale for code outside the SwiftUI view hierarchy.
//  `.environment(\.locale, ...)` only affects Text/LocalizedStringKey resolution
//  inside views — plain `String(localized:)` calls in enums/models/services
//  (e.g. ItemCategory.localizedName) need this explicit locale to also honor
//  the in-app language override instead of silently falling back to the
//  system language. Self-contained (no AppGroupManager dependency) so it can
//  be cross-compiled into the Share Extension and Widget without pulling in
//  AppGroupManager's larger surface.
//

import Foundation

enum AppLocale {
    private static let groupID = "group.com.mbx.ShotTidier"
    private static let overrideKey = "settings.languageOverride"

    static var current: Locale {
        guard let identifier = UserDefaults(suiteName: groupID)?.string(forKey: overrideKey) else {
            return .autoupdatingCurrent
        }
        return Locale(identifier: identifier)
    }

    /// Bundle to pass to `String(localized:bundle:)` call sites outside the
    /// SwiftUI view hierarchy. `String(localized:locale:)`'s `locale` parameter
    /// does NOT override which .lproj resources get searched (verified via
    /// CFBundle's own resolution log — it only consults preferredLocalizations,
    /// i.e. the system language), so we resolve an explicit per-language bundle
    /// here instead and pass THAT, which does work.
    static var bundle: Bundle {
        guard
            let identifier = UserDefaults(suiteName: groupID)?.string(forKey: overrideKey),
            let path = Bundle.main.path(forResource: identifier, ofType: "lproj")
        else {
            return .main
        }
        return Bundle(path: path) ?? .main
    }
}
