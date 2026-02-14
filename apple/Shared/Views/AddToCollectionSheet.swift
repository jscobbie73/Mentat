import SwiftUI

/// Sheet that lets the user pick an existing collection or create a new one,
/// then adds the given fragment to it.
struct AddToCollectionSheet: View {
    let fragment: Fragment

    @Environment(CollectionStore.self) private var collectionStore
    @Environment(\.dismiss) private var dismiss

    @State private var showingNewCollection = false
    @State private var newCollectionName = ""

    var body: some View {
        NavigationStack {
            List {
                if collectionStore.collections.isEmpty {
                    ContentUnavailableView(
                        "No Collections",
                        systemImage: "folder",
                        description: Text("Create your first collection to get started.")
                    )
                } else {
                    ForEach(collectionStore.collections) { collection in
                        Button {
                            Task {
                                try? await collectionStore.addFragment(fragment, to: collection)
                                dismiss()
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(collection.name)
                                        .font(.headline)
                                    Text("\(collection.fragments.count) fragment\(collection.fragments.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if collection.fragments.contains(where: { $0.id == fragment.id }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                        .tint(.primary)
                    }
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("New Collection", systemImage: "folder.badge.plus") {
                        showingNewCollection = true
                    }
                }
            }
            .alert("New Collection", isPresented: $showingNewCollection) {
                TextField("Collection name", text: $newCollectionName)
                Button("Create & Add") {
                    guard !newCollectionName.isEmpty else { return }
                    Task {
                        try? await collectionStore.createCollection(name: newCollectionName)
                        // Add to the newly created collection
                        if let newCollection = collectionStore.collections.first {
                            try? await collectionStore.addFragment(fragment, to: newCollection)
                        }
                        newCollectionName = ""
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) { newCollectionName = "" }
            }
        }
        .presentationDetents([.medium])
    }
}
