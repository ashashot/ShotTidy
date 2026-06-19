//
//  ShareUpdateService.swift
//  ShotTidyShare
//
//  Share-Extension copy of the force-update check.
//  Config.swift is not compiled into this target, so credentials are inlined.
//

import Foundation

@Observable
final class ShareUpdateService {

    enum UpdateState: Equatable {
        case unknown    // not yet checked or network error — do not block
        case current    // remote says no update needed
        case required   // remote says force update
    }

    private(set) var state: UpdateState = .unknown

    // Mirrors Config values (Config.swift is main-target only).
    private let supabaseURL     = "https://qpxvnnkewwolzglynrgj.supabase.co"
    private let appStoreURL     = URL(string: "https://apps.apple.com/app/id6745548716")

    private var configURL: URL? {
        URL(string: "\(supabaseURL)/storage/v1/object/public/config/app-config.json")
    }

    private struct RemoteConfig: Decodable {
        let forceUpdate: Bool
        enum CodingKeys: String, CodingKey { case forceUpdate = "force_update" }
    }

    func check() async {
        guard let url = configURL else { return }
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            let config = try JSONDecoder().decode(RemoteConfig.self, from: data)
            state = config.forceUpdate ? .required : .current
        } catch {
            // Silent failure — do not block the user on network errors.
        }
    }

    var storeURL: URL? { appStoreURL }
}
