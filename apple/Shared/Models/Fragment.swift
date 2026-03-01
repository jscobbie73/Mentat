import Foundation
import SwiftData

/// A single piece of captured knowledge — a note, highlight, bookmark, or clipping.
@Model
final class Fragment {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var sourceURL: URL?
    var sourceType: SourceType
    var metadata: [String: String]
    var createdAt: Date
    var updatedAt: Date

    @Relationship(inverse: \Collection.fragments)
    var collections: [Collection]

    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        sourceURL: URL? = nil,
        sourceType: SourceType = .note,
        metadata: [String: String] = [:],
        createdAt: Date = .now,
        updatedAt: Date = .now,
        collections: [Collection] = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.sourceURL = sourceURL
        self.sourceType = sourceType
        self.metadata = metadata
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.collections = collections
    }

    enum SourceType: String, Codable, CaseIterable {
        case note
        case highlight
        case bookmark
        case article
        case image
        case file
        case share
    }
}
