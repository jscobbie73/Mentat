import Foundation

/// An AI-generated insight: a summary, theme, or suggestion.
struct Insight: Codable, Identifiable {
    let id: UUID
    let fragmentId: UUID?
    let insightType: InsightType
    let content: String
    let metadata: [String: String]
    let createdAt: Date

    enum InsightType: String, Codable {
        case summary
        case theme
        case suggestion
        case relatedTopic
    }
}
