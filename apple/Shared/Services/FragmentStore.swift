import Foundation
import SwiftData

/// Manages fragment data, syncing between local SwiftData and the remote API.
@Observable
final class FragmentStore {
    private(set) var fragments: [Fragment] = []
    private(set) var isLoading = false

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadLocal()
    }

    // MARK: - Local operations

    private func loadLocal() {
        let descriptor = FetchDescriptor<Fragment>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        fragments = (try? modelContext.fetch(descriptor)) ?? []
    }

    func addFragment(title: String, content: String, sourceURL: URL? = nil, sourceType: Fragment.SourceType = .note) async throws {
        // Save locally first
        let fragment = Fragment(
            title: title,
            content: content,
            sourceURL: sourceURL,
            sourceType: sourceType
        )
        modelContext.insert(fragment)
        try modelContext.save()
        loadLocal()

        // Sync to backend
        _ = try await APIClient.shared.createFragment(CreateFragmentRequest(
            title: title,
            content: content,
            sourceUrl: sourceURL?.absoluteString,
            sourceType: sourceType.rawValue,
            metadata: nil
        ))
    }

    func search(query: String) async throws -> [SearchResult] {
        let response = try await APIClient.shared.searchFragments(query: query)
        return response.results
    }

    func getConnections(for fragmentId: UUID) async throws -> [ConnectionResult] {
        let response = try await APIClient.shared.getConnections(fragmentId: fragmentId)
        return response.connections
    }

    func getSuggestions(for fragmentId: UUID) async throws -> [String] {
        let response = try await APIClient.shared.getSuggestions(fragmentId: fragmentId)
        return response.suggestions
    }

    // MARK: - Sync

    func sync() async throws {
        isLoading = true
        defer { isLoading = false }

        let response = try await APIClient.shared.listFragments()
        // Merge remote fragments with local store
        for remote in response.fragments {
            let descriptor = FetchDescriptor<Fragment>(
                predicate: #Predicate { $0.id == remote.id }
            )
            let existing = try modelContext.fetch(descriptor)
            if existing.isEmpty {
                let fragment = Fragment(
                    id: remote.id,
                    title: remote.title,
                    content: remote.content,
                    sourceURL: remote.sourceUrl.flatMap(URL.init(string:)),
                    sourceType: Fragment.SourceType(rawValue: remote.sourceType) ?? .note,
                    createdAt: remote.createdAt,
                    updatedAt: remote.updatedAt
                )
                modelContext.insert(fragment)
            }
        }
        try modelContext.save()
        loadLocal()
    }
}
