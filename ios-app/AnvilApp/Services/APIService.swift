import Foundation
import Combine

class APIService: ObservableObject {
    static let shared = APIService()
    
    private let baseURL = "https://anvil-backend.vercel.app/api"
    private let session = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    // MARK: - Authentication
    
    func login(email: String, password: String) -> AnyPublisher<AuthResponse, APIError> {
        let body = AuthRequest(action: "login", email: email, password: password)
        return post(endpoint: "/auth", body: body)
    }
    
    func register(email: String, password: String, name: String) -> AnyPublisher<AuthResponse, APIError> {
        let body = AuthRequest(action: "register", email: email, password: password, name: name)
        return post(endpoint: "/auth", body: body)
    }
    
    // MARK: - Chat
    
    func sendMessage(messages: [ChatMessage], model: String = "claude-3-sonnet-20240229") -> AnyPublisher<ChatResponse, APIError> {
        let body = ChatRequest(messages: messages, model: model)
        return authenticatedPost(endpoint: "/chat", body: body)
    }
    
    // MARK: - Tools
    
    func executeTool(tool: String, parameters: [String: Any]) -> AnyPublisher<ToolResponse, APIError> {
        let body = ToolRequest(tool: tool, parameters: parameters)
        return authenticatedPost(endpoint: "/tools", body: body)
    }
    
    // MARK: - Generic HTTP Methods
    
    private func post<T: Codable, U: Codable>(endpoint: String, body: T) -> AnyPublisher<U, APIError> {
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return Fail(error: APIError.encodingError(error))
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: U.self, decoder: JSONDecoder())
            .mapError { error in
                if error is DecodingError {
                    return APIError.decodingError(error)
                } else {
                    return APIError.networkError(error)
                }
            }
            .eraseToAnyPublisher()
    }
    
    private func authenticatedPost<T: Codable, U: Codable>(endpoint: String, body: T) -> AnyPublisher<U, APIError> {
        guard let token = AuthService.shared.currentToken else {
            return Fail(error: APIError.unauthorized)
                .eraseToAnyPublisher()
        }
        
        guard let url = URL(string: baseURL + endpoint) else {
            return Fail(error: APIError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            return Fail(error: APIError.encodingError(error))
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                
                if httpResponse.statusCode == 401 {
                    throw APIError.unauthorized
                }
                
                if httpResponse.statusCode >= 400 {
                    throw APIError.serverError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: U.self, decoder: JSONDecoder())
            .mapError { error in
                if let apiError = error as? APIError {
                    return apiError
                } else if error is DecodingError {
                    return APIError.decodingError(error)
                } else {
                    return APIError.networkError(error)
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Request/Response Models

struct AuthRequest: Codable {
    let action: String
    let email: String
    let password: String
    let name: String?
    
    init(action: String, email: String, password: String, name: String? = nil) {
        self.action = action
        self.email = email
        self.password = password
        self.name = name
    }
}

struct AuthResponse: Codable {
    let success: Bool
    let token: String
    let user: User
}

struct ChatRequest: Codable {
    let messages: [ChatMessage]
    let model: String
    let maxTokens: Int
    
    init(messages: [ChatMessage], model: String, maxTokens: Int = 4096) {
        self.messages = messages
        self.model = model
        self.maxTokens = maxTokens
    }
    
    enum CodingKeys: String, CodingKey {
        case messages, model
        case maxTokens = "max_tokens"
    }
}

struct ChatMessage: Codable {
    let role: String
    let content: String
    
    init(role: Message.MessageRole, content: String) {
        self.role = role.rawValue
        self.content = content
    }
}

struct ChatResponse: Codable {
    let id: String
    let content: [ContentBlock]
    let model: String
    let role: String
    let usage: TokenUsage
}

struct ContentBlock: Codable {
    let type: String
    let text: String?
}

struct ToolRequest: Codable {
    let tool: String
    let parameters: [String: Any]
    
    init(tool: String, parameters: [String: Any]) {
        self.tool = tool
        self.parameters = parameters
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tool, forKey: .tool)
        
        // Convert [String: Any] to [String: AnyCodable] for encoding
        let codableParams = parameters.mapValues { AnyCodable($0) }
        try container.encode(codableParams, forKey: .parameters)
    }
    
    enum CodingKeys: String, CodingKey {
        case tool, parameters
    }
}

struct ToolResponse: Codable {
    let success: Bool?
    let result: String?
    let content: String?
    let files: [String]?
    let error: String?
    let message: String?
    let status: Int?
    let headers: [String: String]?
    let body: String?
}

// MARK: - Error Types

enum APIError: Error, LocalizedError {
    case invalidURL
    case unauthorized
    case networkError(Error)
    case decodingError(Error)
    case encodingError(Error)
    case serverError(Int)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .unauthorized:
            return "Unauthorized - please log in again"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data parsing error: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Data encoding error: \(error.localizedDescription)"
        case .serverError(let code):
            return "Server error (\(code))"
        case .invalidResponse:
            return "Invalid response from server"
        }
    }
}