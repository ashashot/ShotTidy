//
//  KeychainManager.swift
//  ShotTidy
//
//  Secure storage for the OpenAI API key in Keychain.
//

import Foundation
import Security

final class KeychainManager {

    static let shared = KeychainManager()
    private init() {}

    private let service = "com.mbx.ShotTidy"
    private let account = "openai-api-key"

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

    /// Getter/setter for the OpenAI API key
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
}
