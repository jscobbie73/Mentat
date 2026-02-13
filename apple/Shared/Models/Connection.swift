import Foundation

/// An AI-discovered relationship between two fragments.
struct Connection: Codable, Identifiable {
    let id: UUID
    let fragmentAId: UUID
    let fragmentBId: UUID
    let similarity: Float
    let aiSummary: String?
    let createdAt: Date
}
