import Foundation

// MARK: - Request models

struct CreateFragmentRequest: Encodable {
    let title: String
    let content: String
    let sourceUrl: String?
    let sourceType: String
    let metadata: [String: String]?
}

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let email: String
    let password: String
    let displayName: String
}

// MARK: - Response models

struct AuthResponse: Decodable {
    let user: UserResponse
    let token: String
}

struct UserResponse: Decodable {
    let id: UUID
    let email: String
    let displayName: String
}

struct FragmentResponse: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let title: String
    let content: String
    let sourceUrl: String?
    let sourceType: String
    let metadata: [String: String]
    let createdAt: Date
    let updatedAt: Date
}

struct FragmentListResponse: Decodable {
    let fragments: [FragmentResponse]
    let limit: Int
    let offset: Int
}

struct SearchResponse: Decodable {
    let results: [SearchResult]
}

struct SearchResult: Decodable, Identifiable {
    let id: UUID
    let title: String
    let content: String
    let similarity: Float
}

struct ConnectionsResponse: Decodable {
    let connections: [ConnectionResult]
}

struct ConnectionResult: Decodable, Identifiable {
    let id: UUID
    let title: String
    let content: String
    let similarity: Float
}

struct SuggestionsResponse: Decodable {
    let suggestions: [String]
}
