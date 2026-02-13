import Foundation

/// HTTP client for communicating with the Mentat backend API.
actor APIClient {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession
    private var authToken: String?

    init(
        baseURL: URL = URL(string: "https://api.mentat.app")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - Auth

    func setAuthToken(_ token: String?) {
        self.authToken = token
    }

    // MARK: - Fragments

    func createFragment(_ request: CreateFragmentRequest) async throws -> FragmentResponse {
        try await post("/api/fragments", body: request)
    }

    func listFragments(limit: Int = 50, offset: Int = 0) async throws -> FragmentListResponse {
        try await get("/api/fragments?limit=\(limit)&offset=\(offset)")
    }

    func searchFragments(query: String) async throws -> SearchResponse {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        return try await get("/api/fragments/search?q=\(encoded)")
    }

    func getConnections(fragmentId: UUID) async throws -> ConnectionsResponse {
        try await get("/api/fragments/\(fragmentId)/connections")
    }

    func getSuggestions(fragmentId: UUID) async throws -> SuggestionsResponse {
        try await get("/api/fragments/\(fragmentId)/suggestions")
    }

    // MARK: - Auth endpoints

    func login(email: String, password: String) async throws -> AuthResponse {
        try await post("/api/auth/login", body: LoginRequest(email: email, password: password))
    }

    func register(email: String, password: String, displayName: String) async throws -> AuthResponse {
        try await post("/api/auth/register", body: RegisterRequest(
            email: email, password: password, displayName: displayName
        ))
    }

    // MARK: - Private

    private func get<T: Decodable>(_ path: String) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyAuth(&request)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder.api.decode(T.self, from: data)
    }

    private func post<Body: Encodable, T: Decodable>(_ path: String, body: Body) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder.api.encode(body)
        applyAuth(&request)
        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try JSONDecoder.api.decode(T.self, from: data)
    }

    private func applyAuth(_ request: inout URLRequest) {
        if let token = authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw APIError.httpError(statusCode: http.statusCode)
        }
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "Server returned status \(code)"
        }
    }
}

// MARK: - JSON coding helpers

extension JSONDecoder {
    static let api: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

extension JSONEncoder {
    static let api: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
