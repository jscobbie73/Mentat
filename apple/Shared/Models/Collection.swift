import Foundation
import SwiftData

/// A user-organized group of related fragments.
@Model
final class Collection {
    @Attribute(.unique) var id: UUID
    var name: String
    var collectionDescription: String?
    var createdAt: Date
    var updatedAt: Date

    var fragments: [Fragment]

    init(
        id: UUID = UUID(),
        name: String,
        collectionDescription: String? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        fragments: [Fragment] = []
    ) {
        self.id = id
        self.name = name
        self.collectionDescription = collectionDescription
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.fragments = fragments
    }
}
