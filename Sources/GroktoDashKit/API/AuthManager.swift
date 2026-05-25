import Foundation
import Security

/// Manages secure storage of gateway URL and API key in the macOS Keychain.
public final class AuthManager: @unchecked Sendable {
    private let service = "com.groktopus.groktodash"

    public init() {}

    // MARK: - Gateway URL

    public func saveGatewayURL(_ url: String) throws {
        try save(key: "gatewayUrl", value: url)
    }

    public func getGatewayURL() -> String? {
        load(key: "gatewayUrl")
    }

    // MARK: - API Key

    public func saveAPIKey(_ key: String) throws {
        try save(key: "apiKey", value: key)
    }

    public func getAPIKey() -> String? {
        load(key: "apiKey")
    }

    // MARK: - Keychain Operations

    private func save(key: String, value: String) throws {
        // Delete existing item first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: Data(value.utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthError.keychainError(status: status)
        }
    }

    private func load(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }
}

public enum AuthError: Error {
    case keychainError(status: OSStatus)
}
