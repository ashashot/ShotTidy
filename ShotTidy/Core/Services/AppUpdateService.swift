//
//  AppUpdateService.swift
//  ShotTidy
//
//  Fetches a remote JSON config from Supabase Storage and determines
//  whether the app must be force-updated before further use.
//
//  Remote config format (Supabase Storage → bucket "config" → app-config.json):
//    { "force_update": false }
//
//  When force_update is true every screen in the app is covered by ForceUpdateView.
//  Network errors are treated as "no update required" so offline users are not blocked.
//

import Foundation

@Observable
final class AppUpdateService {

    enum UpdateState: Equatable {
        case unknown    // not yet checked or network error — do not block
        case current    // remote says no update needed
        case required   // remote says force update
    }

    private(set) var state: UpdateState = .unknown

    // MARK: - Remote config model

    private struct RemoteConfig: Decodable {
        let forceUpdate: Bool
        enum CodingKeys: String, CodingKey { case forceUpdate = "force_update" }
    }

    // MARK: - Check

    func check() async {
        guard let url = Config.appConfigURL else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            let config = try JSONDecoder().decode(RemoteConfig.self, from: data)
            state = config.forceUpdate ? .required : .current
        } catch {
            // Silent failure — do not block the user on network errors.
        }
    }
}
