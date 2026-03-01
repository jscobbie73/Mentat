import Foundation
import SwiftData

/// Manages collection data, syncing between local SwiftData and the remote API.
@Observable
final class CollectionStore {
    private(set) var collections: [Collection] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadLocal()
    }

    // MARK: - Local operations

    private func loadLocal() {
        let descriptor = FetchDescriptor<Collection>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        collections = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - CRUD

    func createCollection(name: String, description: String? = nil) async throws {
        // Save locally
        let collection = Collection(name: name, collectionDescription: description)
        modelContext.insert(collection)
        try modelContext.save()
        loadLocal()

        // Sync to backend
        do {
            _ = try await APIClient.shared.createCollection(name: name, description: description)
        } catch {
            errorMessage = "Collection saved locally but failed to sync: \(error.localizedDescription)"
        }
    }

    func updateCollection(_ collection: Collection, name: String?, description: String?) async throws {
        if let name { collection.name = name }
        if let description { collection.collectionDescription = description }
        collection.updatedAt = .now
        try modelContext.save()
        loadLocal()

        do {
            _ = try await APIClient.shared.updateCollection(id: collection.id, name: name, description: description)
        } catch {
            errorMessage = "Collection updated locally but failed to sync: \(error.localizedDescription)"
        }
    }

    func deleteCollection(_ collection: Collection) async throws {
        let collectionId = collection.id
        modelContext.delete(collection)
        try modelContext.save()
        loadLocal()

        do {
            try await APIClient.shared.deleteCollection(id: collectionId)
        } catch {
            errorMessage = "Collection deleted locally but failed to sync: \(error.localizedDescription)"
        }
    }

    func addFragment(_ fragment: Fragment, to collection: Collection) async throws {
        collection.fragments.append(fragment)
        collection.updatedAt = .now
        try modelContext.save()
        loadLocal()

        do {
            try await APIClient.shared.addFragmentToCollection(collectionId: collection.id, fragmentId: fragment.id)
        } catch {
            errorMessage = "Fragment added locally but failed to sync: \(error.localizedDescription)"
        }
    }

    func removeFragment(_ fragment: Fragment, from collection: Collection) async throws {
        collection.fragments.removeAll { $0.id == fragment.id }
        collection.updatedAt = .now
        try modelContext.save()
        loadLocal()

        do {
            try await APIClient.shared.removeFragmentFromCollection(collectionId: collection.id, fragmentId: fragment.id)
        } catch {
            errorMessage = "Fragment removed locally but failed to sync: \(error.localizedDescription)"
        }
    }

    // MARK: - Remote detail

    func getCollectionDetail(id: UUID) async throws -> CollectionDetailResponse {
        try await APIClient.shared.getCollection(id: id)
    }

    // MARK: - Sync

    func sync() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let response = try await APIClient.shared.listCollections()
        for remote in response.collections {
            let descriptor = FetchDescriptor<Collection>(
                predicate: #Predicate { $0.id == remote.id }
            )
            let existing = try modelContext.fetch(descriptor)
            if existing.isEmpty {
                let collection = Collection(
                    id: remote.id,
                    name: remote.name,
                    collectionDescription: remote.description,
                    createdAt: remote.createdAt,
                    updatedAt: remote.updatedAt
                )
                modelContext.insert(collection)
            }
        }
        try modelContext.save()
        loadLocal()
    }
}
