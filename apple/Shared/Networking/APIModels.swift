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

struct AppleSignInRequest: Encodable {
    let identityToken: String
    let authorizationCode: String
    let displayName: String?
}

struct CreateCollectionRequest: Encodable {
    let name: String
    let description: String?
}

struct UpdateCollectionRequest: Encodable {
    let name: String?
    let description: String?
}

struct AddFragmentToCollectionRequest: Encodable {
    let fragmentId: UUID
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
    var id: UUID? // nil for live-similarity fallback connections
    let fragmentId: UUID
    let title: String
    let content: String
    let sourceType: String
    let similarity: Float
    let aiSummary: String?
    let fragmentCreatedAt: Date?
}

struct SuggestionsResponse: Decodable {
    let suggestions: [String]
}

// MARK: - Collection responses

struct CollectionResponse: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let description: String?
    let createdAt: Date
    let updatedAt: Date
}

struct CollectionListResponse: Decodable {
    let collections: [CollectionResponse]
}

struct CollectionDetailResponse: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let name: String
    let description: String?
    let createdAt: Date
    let updatedAt: Date
    let fragments: [FragmentResponse]
    let limit: Int
    let offset: Int
}

// MARK: - Insight responses

struct InsightResponse: Decodable, Identifiable {
    let id: UUID
    let userId: UUID
    let fragmentId: UUID?
    let insightType: String
    let content: String
    let metadata: [String: String]
    let createdAt: Date
}

struct InsightListResponse: Decodable {
    let insights: [InsightResponse]
    let limit: Int
    let offset: Int
}

struct GenerateInsightsResponse: Decodable {
    let insights: [InsightResponse]
}
