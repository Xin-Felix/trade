import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()

    private let service = "com.yingplus.auth"
    private let accessTokenAccount = "access_token"
    private let refreshTokenAccount = "refresh_token"

    private init() {}

    // MARK: - Access Token

    func save(_ value: String) throws {
        try save(value, account: accessTokenAccount)
    }

    func read() -> String? {
        return read(account: accessTokenAccount)
    }

    func delete() {
        delete(account: accessTokenAccount)
        delete(account: refreshTokenAccount)
    }

    // MARK: - Refresh Token

    func saveRefreshToken(_ value: String) throws {
        try save(value, account: refreshTokenAccount)
    }

    func readRefreshToken() -> String? {
        return read(account: refreshTokenAccount)
    }

    // MARK: - Private Helpers

    private func save(_ value: String, account: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.invalidData
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }

    private func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }

    private func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}

enum KeychainError: Error {
    case invalidData
    case saveFailed(OSStatus)
}

extension KeychainError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidData:
            return "无法编码 token"
        case .saveFailed(let status):
            return "Keychain 保存失败，状态码: \(status)"
        }
    }
}
