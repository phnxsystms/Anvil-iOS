import Foundation
import Combine
import Security

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private let keychain = KeychainHelper()
    private let userDefaultsKey = "current_user"
    private let tokenKey = "auth_token"
    private var cancellables = Set<AnyCancellable>()
    
    var currentToken: String? {
        return keychain.get(tokenKey)
    }
    
    private init() {
        // Load saved user on init
        loadSavedUser()
    }
    
    // MARK: - Authentication Methods
    
    func login(email: String, password: String) -> AnyPublisher<Void, APIError> {
        isLoading = true
        
        return APIService.shared.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .tryMap { [weak self] response in
                self?.handleAuthSuccess(token: response.token, user: response.user)
            }
            .mapError { $0 as? APIError ?? APIError.networkError($0) }
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            })
            .eraseToAnyPublisher()
    }
    
    func register(email: String, password: String, name: String) -> AnyPublisher<Void, APIError> {
        isLoading = true
        
        return APIService.shared.register(email: email, password: password, name: name)
            .receive(on: DispatchQueue.main)
            .tryMap { [weak self] response in
                self?.handleAuthSuccess(token: response.token, user: response.user)
            }
            .mapError { $0 as? APIError ?? APIError.networkError($0) }
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            })
            .eraseToAnyPublisher()
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
        
        // Clear stored data
        keychain.delete(tokenKey)
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
    
    // MARK: - Private Methods
    
    private func handleAuthSuccess(token: String, user: User) {
        // Store token securely
        keychain.set(token, forKey: tokenKey)
        
        // Store user data
        if let userData = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(userData, forKey: userDefaultsKey)
        }
        
        // Update state
        currentUser = user
        isAuthenticated = true
    }
    
    private func loadSavedUser() {
        // Check if we have a token
        guard currentToken != nil else { return }
        
        // Load user data
        guard let userData = UserDefaults.standard.data(forKey: userDefaultsKey),
              let user = try? JSONDecoder().decode(User.self, from: userData) else {
            logout() // Clear invalid data
            return
        }
        
        currentUser = user
        isAuthenticated = true
    }
}

// MARK: - Keychain Helper

private class KeychainHelper {
    func set(_ value: String, forKey key: String) {
        let data = Data(value.utf8)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    func get(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == noErr,
           let data = dataTypeRef as? Data,
           let value = String(data: data, encoding: .utf8) {
            return value
        }
        
        return nil
    }
    
    func delete(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

// MARK: - Validation Helpers

extension AuthService {
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[\\w\\.-]+@([\\w\\-]+\\.)+[A-Z]{2,}$"
        let emailPredicate = NSPredicate(format:"SELF MATCHES[c] %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8
    }
    
    static func passwordStrength(_ password: String) -> PasswordStrength {
        var score = 0
        
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.rangeOfCharacter(from: .lowercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .uppercaseLetters) != nil { score += 1 }
        if password.rangeOfCharacter(from: .decimalDigits) != nil { score += 1 }
        if password.rangeOfCharacter(from: .punctuationCharacters.union(.symbols)) != nil { score += 1 }
        
        switch score {
        case 0...2: return .weak
        case 3...4: return .medium
        default: return .strong
        }
    }
    
    enum PasswordStrength {
        case weak, medium, strong
        
        var description: String {
            switch self {
            case .weak: return "Weak"
            case .medium: return "Medium"
            case .strong: return "Strong"
            }
        }
        
        var color: String {
            switch self {
            case .weak: return "red"
            case .medium: return "orange"
            case .strong: return "green"
            }
        }
    }
}