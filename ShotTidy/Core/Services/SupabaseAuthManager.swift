//
//  SupabaseAuthManager.swift
//  ShotTidy
//
//  Anonymous Supabase Auth session shared by the main app and the Share
//  Extension. Add this file to both targets (like AppGroupManager); the
//  session is stored in the shared Keychain access group so both processes
//  reuse one identity.
//
//  The manager is deliberately fail-open: when anonymous sign-in is
//  unavailable (feature disabled server-side, no network), callers receive
//  the legacy anon key and the backend serves the request under its
//  transition rules.
//

import Foundation
import Security

actor SupabaseAuthManager {

    static let shared = SupabaseAuthManager()

    // Self-contained credentials — this file is compiled into multiple
    // targets, some of which do not include Config.swift.
    private static let supabaseURL = "https://qpxvnnkewwolzglynrgj.supabase.co"
    private static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFweHZubmtld3dvbHpnbHlucmdqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk3NDkzMzksImV4cCI6MjA5NTMyNTMzOX0.fYzLDOILNm3I2TU6QobG5HGQQxe8kJAfPCI9kSABpec"

    // MARK: - Session

    struct Session: Codable {
        var accessToken: String
        var refreshToken: String
        var expiresAt: Date
        var userId: UUID
    }

    private var session: Session?
    /// Deduplicates concurrent sign-in/refresh attempts (actor reentrancy:
    /// several API calls may hit an expired session at the same time).
    private var pendingAuthTask: Task<Session?, Never>?
    /// After a failed sign-in (e.g. anonymous auth disabled server-side),
    /// don't retry on every API call — wait out this cooldown first.
    private var lastAuthFailure: Date?
    private static let authRetryCooldown: TimeInterval = 5 * 60

    private init() {
        session = Self.loadSession()
    }

    // MARK: - Public API

    /// Bearer token for Edge Function calls: a valid anonymous-user access
    /// token when possible, otherwise the legacy anon key (fail-open).
    func bearerToken() async -> String {
        (await validSession())?.accessToken ?? Self.anonKey
    }

    /// The anonymous user's UUID — used as `appAccountToken` for purchases
    /// and as the server-side quota identity.
    func currentUserId() async -> UUID? {
        (await validSession())?.userId
    }

    /// Call after a 401 from an Edge Function: invalidates the cached access
    /// token, forces a refresh (or a fresh anonymous sign-in) and returns the
    /// new token, or nil when recovery failed.
    func recoverFromAuthFailure() async -> String? {
        session?.expiresAt = .distantPast
        return (await validSession())?.accessToken
    }

    // MARK: - Session lifecycle

    private func validSession() async -> Session? {
        if let current = session, current.expiresAt.timeIntervalSinceNow > 60 {
            return current
        }

        if let pending = pendingAuthTask {
            return await pending.value
        }

        if let failure = lastAuthFailure,
           Date().timeIntervalSince(failure) < Self.authRetryCooldown {
            return nil
        }

        let task = Task<Session?, Never> { [current = session] in
            if let current, let refreshed = await Self.refresh(current) {
                return refreshed
            }
            return await Self.signInAnonymously()
        }
        pendingAuthTask = task
        let result = await task.value
        pendingAuthTask = nil

        if let result {
            session = result
            lastAuthFailure = nil
            Self.storeSession(result)
        } else {
            lastAuthFailure = Date()
        }
        return result
    }

    // MARK: - GoTrue REST

    private static func signInAnonymously() async -> Session? {
        guard let url = URL(string: "\(supabaseURL)/auth/v1/signup") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data("{}".utf8)
        request.timeoutInterval = 15
        return await performAuthRequest(request)
    }

    private static func refresh(_ session: Session) async -> Session? {
        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=refresh_token") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(
            withJSONObject: ["refresh_token": session.refreshToken]
        )
        request.timeoutInterval = 15
        return await performAuthRequest(request)
    }

    private static func performAuthRequest(_ request: URLRequest) async -> Session? {
        guard
            let (data, response) = try? await URLSession.shared.data(for: request),
            let http = response as? HTTPURLResponse, http.statusCode == 200,
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let accessToken = json["access_token"] as? String,
            let refreshToken = json["refresh_token"] as? String,
            let user = json["user"] as? [String: Any],
            let idString = user["id"] as? String,
            let userId = UUID(uuidString: idString)
        else { return nil }

        let expiresIn = (json["expires_in"] as? Double) ?? 3600
        return Session(
            accessToken: accessToken,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(expiresIn),
            userId: userId
        )
    }

    // MARK: - Keychain persistence (shared access group, same as UsageStore)

    private static let account = "auth.session"
    private static let service = "com.mbx.ShotTidier.auth"

    /// Same entitled access-group suffix as UsageStore, so both targets read
    /// one session. Resolved lazily via the bundle-seed-ID probe.
    private static let accessGroup: String? =
        resolveAccessGroup(suffix: "com.mbx.ShotTidier.usage")

    private static func loadSession() -> Session? {
        var query = keychainQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let session = try? JSONDecoder().decode(Session.self, from: data)
        else { return nil }
        return session
    }

    private static func storeSession(_ session: Session) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        let query = keychainQuery()

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insert = query
            insert[kSecValueData as String] = data
            insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            SecItemAdd(insert as CFDictionary, nil)
        }
    }

    private static func keychainQuery() -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
        ]
        if let accessGroup { query[kSecAttrAccessGroup as String] = accessGroup }
        #if os(macOS)
        // On macOS, access groups only work with the data protection keychain
        // (the iOS-style keychain); the legacy file-based keychain ignores them.
        query[kSecUseDataProtectionKeychain as String] = true
        #endif
        return query
    }

    /// Discovers the app's keychain access-group prefix (the Team ID) at
    /// runtime using the bundle-seed-ID probe, then appends `suffix` to form
    /// the fully-qualified shared group. Returns nil when discovery fails —
    /// the session then stays per-target instead of shared.
    private static func resolveAccessGroup(suffix: String) -> String? {
        var probe: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "accessGroupProbe",
            kSecAttrService as String: "accessGroupProbe",
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        #if os(macOS)
        probe[kSecUseDataProtectionKeychain as String] = true
        #endif
        var result: AnyObject?
        var status = SecItemCopyMatching(probe as CFDictionary, &result)
        if status == errSecItemNotFound {
            status = SecItemAdd(probe as CFDictionary, &result)
        }
        guard status == errSecSuccess,
              let attrs = result as? [String: Any],
              let group = attrs[kSecAttrAccessGroup as String] as? String,
              let prefix = group.components(separatedBy: ".").first
        else { return nil }
        return "\(prefix).\(suffix)"
    }
}
