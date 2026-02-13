import Foundation
import AuthenticationServices

/// Manages user authentication state across the app.
@Observable
final class AuthManager {
    private(set) var isAuthenticated = false
    private(set) var currentUser: UserResponse?

    private let keychain = KeychainHelper.shared

    init() {
        // Restore saved session
        if let token = keychain.read(key: "auth_token") {
            Task {
                await APIClient.shared.setAuthToken(token)
            }
            isAuthenticated = true
        }
    }

    func login(email: String, password: String) async throws {
        let response = try await APIClient.shared.login(email: email, password: password)
        await APIClient.shared.setAuthToken(response.token)
        keychain.save(key: "auth_token", value: response.token)
        currentUser = response.user
        isAuthenticated = true
    }

    func register(email: String, password: String, displayName: String) async throws {
        let response = try await APIClient.shared.register(
            email: email, password: password, displayName: displayName
        )
        await APIClient.shared.setAuthToken(response.token)
        keychain.save(key: "auth_token", value: response.token)
        currentUser = response.user
        isAuthenticated = true
    }

    func signOut() {
        keychain.delete(key: "auth_token")
        Task { await APIClient.shared.setAuthToken(nil) }
        currentUser = nil
        isAuthenticated = false
    }
}

// MARK: - Keychain helper

final class KeychainHelper {
    static let shared = KeychainHelper()
    private init() {}

    func save(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.mentat.app",
            kSecValueData as String: data,
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.mentat.app",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.mentat.app",
        ]
        SecItemDelete(query as CFDictionary)
    }
}
