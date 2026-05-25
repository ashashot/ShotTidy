//
//  KeychainManager.swift
//  ShotTidy
//
//  Secure storage for the OpenAI API key in Keychain.
//  The `sharedAPIKey` property uses a Keychain Access Group so the
//  Share Extension (ShotTidyShare) can read the key without going
//  through insecure UserDefaults.
//
//  Both targets must list "$(AppIdentifierPrefix)mbx.ShotTidy" in their
//  keychain-access-groups entitlement (already done in .entitlements files).
//

import Foundation
import Security

final class KeychainManager {

    static let shared = KeychainManager()
    private init() {}

    private let service = "com.mbx.ShotTidy"
    private let account = "openai-api-key"

    // Keychain Access Group shared between the main app and the Share Extension.
    // $(AppIdentifierPrefix) expands to the Team ID at code-signing time → "FK4KSS322U."
    private static let sharedAccessGroup = "FK4KSS322U.mbx.ShotTidy"
    // Separate account key so the shared entry never collides with the private one.
    private let sharedAccount = "openai-api-key-shared"

    // MARK: - Save

    @discardableResult
    func saveAPIKey(_ key: String) -> Bool {
        let data = Data(key.utf8)

        // Try updating the existing entry first
        let updateQuery: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        let attributes: [CFString: Any] = [kSecValueData: data]
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecItemNotFound {
            // Add a new entry
            let addQuery: [CFString: Any] = [
                kSecClass:       kSecClassGenericPassword,
                kSecAttrService: service,
                kSecAttrAccount: account,
                kSecValueData:   data
            ]
            return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
        }

        return updateStatus == errSecSuccess
    }

    // MARK: - Get

    func getAPIKey() -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      account,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty else {
            return nil
        }
        return key
    }

    // MARK: - Delete

    @discardableResult
    func deleteAPIKey() -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    // MARK: - Check

    var hasAPIKey: Bool {
        getAPIKey() != nil
    }

    // MARK: - Computed property (convenient access)

    /// Getter/setter for the OpenAI API key (private, main app only)
    var openAIAPIKey: String? {
        get { getAPIKey() }
        set {
            if let key = newValue, !key.isEmpty {
                saveAPIKey(key)
            } else {
                deleteAPIKey()
            }
        }
    }

    // MARK: - Shared API Key (accessible by the Share Extension via Keychain Access Group)

    /// Reads or writes the API key in the shared Keychain Access Group.
    /// Both the main app and ShotTidyShare can access this item.
    var sharedAPIKey: String? {
        get { getSharedKey() }
        set {
            if let key = newValue, !key.isEmpty {
                saveSharedKey(key)
            } else {
                deleteSharedKey()
            }
        }
    }

    private func saveSharedKey(_ key: String) {
        let data = Data(key.utf8)

        // Try updating first
        let updateQuery: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrService:     service,
            kSecAttrAccount:     sharedAccount,
            kSecAttrAccessGroup: KeychainManager.sharedAccessGroup
        ]
        let status = SecItemUpdate(updateQuery as CFDictionary, [kSecValueData: data] as CFDictionary)

        if status == errSecItemNotFound {
            let addQuery: [CFString: Any] = [
                kSecClass:           kSecClassGenericPassword,
                kSecAttrService:     service,
                kSecAttrAccount:     sharedAccount,
                kSecAttrAccessGroup: KeychainManager.sharedAccessGroup,
                kSecValueData:       data
            ]
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private func getSharedKey() -> String? {
        let query: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrService:     service,
            kSecAttrAccount:     sharedAccount,
            kSecAttrAccessGroup: KeychainManager.sharedAccessGroup,
            kSecReturnData:      true,
            kSecMatchLimit:      kSecMatchLimitOne
        ]

        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty else { return nil }
        return key
    }

    private func deleteSharedKey() {
        let query: [CFString: Any] = [
            kSecClass:           kSecClassGenericPassword,
            kSecAttrService:     service,
            kSecAttrAccount:     sharedAccount,
            kSecAttrAccessGroup: KeychainManager.sharedAccessGroup
        ]
        SecItemDelete(query as CFDictionary)
    }
}
