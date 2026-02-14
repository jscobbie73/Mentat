import SwiftUI

struct MobileContentView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(FragmentStore.self) private var store

    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showingNewFragment = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // Library tab
            NavigationStack {
                fragmentList
                    .navigationTitle("Library")
                    .searchable(text: $searchText, prompt: "Search your knowledge...")
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: { showingNewFragment = true }) {
                                Image(systemName: "plus")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
            .tag(0)

            // Discover tab - AI connections and insights
            NavigationStack {
                DiscoverView()
                    .navigationTitle("Discover")
            }
            .tabItem {
                Label("Discover", systemImage: "sparkles")
            }
            .tag(1)

            // Collections tab
            NavigationStack {
                CollectionsView()
                    .navigationTitle("Collections")
            }
            .tabItem {
                Label("Collections", systemImage: "folder")
            }
            .tag(2)

            // Settings tab
            NavigationStack {
                MobileSettingsView()
                    .navigationTitle("Settings")
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(3)
        }
        .sheet(isPresented: $showingNewFragment) {
            MobileNewFragmentView()
        }
    }

    private var fragmentList: some View {
        List(store.fragments) { fragment in
            NavigationLink {
                MobileFragmentDetailView(fragment: fragment)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(fragment.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(fragment.content)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    HStack {
                        Label(fragment.sourceType.rawValue.capitalized, systemImage: "tag")
                            .font(.caption)
                        Spacer()
                        Text(fragment.createdAt, style: .relative)
                            .font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        }
        .refreshable {
            try? await store.sync()
        }
    }
}

// MARK: - Mobile Fragment Detail

struct MobileFragmentDetailView: View {
    let fragment: Fragment

    @Environment(FragmentStore.self) private var store
    @State private var connections: [ConnectionResult] = []
    @State private var suggestions: [String] = []
    @State private var isLoadingConnections = false
    @State private var isLoadingSuggestions = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(fragment.title)
                    .font(.title)
                    .fontWeight(.bold)

                HStack {
                    Label(fragment.sourceType.rawValue.capitalized, systemImage: "tag")
                        .font(.subheadline)
                        .foregroundStyle(.tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.tint.opacity(0.1), in: Capsule())

                    Spacer()

                    Text(fragment.createdAt, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()

                Text(fragment.content)
                    .font(.body)
                    .textSelection(.enabled)

                if let url = fragment.sourceURL {
                    Link(destination: url) {
                        Label(url.host ?? url.absoluteString, systemImage: "link")
                            .font(.subheadline)
                    }
                }

                Divider()

                // Connections
                VStack(alignment: .leading, spacing: 12) {
                    Label("Connections", systemImage: "point.3.connected.trianglepath.dotted")
                        .font(.title3)
                        .fontWeight(.semibold)

                    if isLoadingConnections {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if connections.isEmpty {
                        Text("No connections discovered yet.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(connections) { connection in
                            mobileConnectionCard(connection)
                        }
                    }
                }

                Divider()

                // Suggestions
                VStack(alignment: .leading, spacing: 12) {
                    Label("Further Reading", systemImage: "lightbulb")
                        .font(.title3)
                        .fontWeight(.semibold)

                    if isLoadingSuggestions {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if suggestions.isEmpty {
                        Text("Add more fragments for AI suggestions.")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(suggestions, id: \.self) { suggestion in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "arrow.right.circle")
                                    .foregroundStyle(.tint)
                                    .font(.caption)
                                    .padding(.top, 3)
                                Text(suggestion)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(fragment.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadConnections()
            await loadSuggestions()
        }
    }

    private func mobileConnectionCard(_ connection: ConnectionResult) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(connection.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)

            if let summary = connection.aiSummary {
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.8))
                    .lineLimit(3)
            } else {
                Text(connection.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            HStack {
                let percent = Int(connection.similarity * 100)
                let color: Color = connection.similarity > 0.9 ? .green : connection.similarity > 0.8 ? .orange : .blue
                Text("\(percent)% match")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.12), in: Capsule())

                Spacer()
            }
        }
        .padding(12)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
    }

    private func loadConnections() async {
        isLoadingConnections = true
        defer { isLoadingConnections = false }
        connections = (try? await store.getConnections(for: fragment.id)) ?? []
    }

    private func loadSuggestions() async {
        isLoadingSuggestions = true
        defer { isLoadingSuggestions = false }
        suggestions = (try? await store.getSuggestions(for: fragment.id)) ?? []
    }
}

// MARK: - Placeholder views (will be replaced in Phase 4 & 5)

struct DiscoverView: View {
    @Environment(FragmentStore.self) private var store
    @State private var insights: [InsightResponse] = []
    @State private var isLoading = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading insights...")
            } else if insights.isEmpty {
                ContentUnavailableView(
                    "Discover Connections",
                    systemImage: "sparkles",
                    description: Text("As you add more fragments, Mentat will surface connections and insights here.")
                )
            } else {
                List(insights) { insight in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(insight.insightType.capitalized)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.tint)
                        Text(insight.content)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .task {
            isLoading = true
            defer { isLoading = false }
            let response = try? await APIClient.shared.listInsights()
            insights = response?.insights ?? []
        }
    }
}

struct CollectionsView: View {
    @Environment(CollectionStore.self) private var collectionStore
    @Environment(FragmentStore.self) private var fragmentStore
    @State private var showingNewCollection = false
    @State private var newCollectionName = ""

    var body: some View {
        Group {
            if collectionStore.collections.isEmpty {
                ContentUnavailableView(
                    "No Collections Yet",
                    systemImage: "folder",
                    description: Text("Create collections to organize your fragments.")
                )
            } else {
                List {
                    ForEach(collectionStore.collections) { collection in
                        NavigationLink {
                            CollectionDetailView(collection: collection)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(collection.name)
                                    .font(.headline)
                                if let desc = collection.collectionDescription {
                                    Text(desc)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Text("\(collection.fragments.count) fragment\(collection.fragments.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let collection = collectionStore.collections[index]
                            Task { try? await collectionStore.deleteCollection(collection) }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewCollection = true }) {
                    Image(systemName: "folder.badge.plus")
                }
            }
        }
        .alert("New Collection", isPresented: $showingNewCollection) {
            TextField("Collection name", text: $newCollectionName)
            Button("Create") {
                guard !newCollectionName.isEmpty else { return }
                Task {
                    try? await collectionStore.createCollection(name: newCollectionName)
                    newCollectionName = ""
                }
            }
            Button("Cancel", role: .cancel) { newCollectionName = "" }
        }
        .refreshable {
            try? await collectionStore.sync()
        }
    }
}

struct CollectionDetailView: View {
    let collection: Collection
    @Environment(CollectionStore.self) private var collectionStore

    var body: some View {
        List {
            if collection.fragments.isEmpty {
                ContentUnavailableView(
                    "Empty Collection",
                    systemImage: "folder",
                    description: Text("Add fragments to this collection from the fragment detail view.")
                )
            } else {
                ForEach(collection.fragments) { fragment in
                    NavigationLink {
                        MobileFragmentDetailView(fragment: fragment)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(fragment.title)
                                .font(.headline)
                                .lineLimit(1)
                            Text(fragment.content)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        let fragment = collection.fragments[index]
                        Task { try? await collectionStore.removeFragment(fragment, from: collection) }
                    }
                }
            }
        }
        .navigationTitle(collection.name)
    }
}

struct MobileSettingsView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        Form {
            Section("Account") {
                if authManager.isAuthenticated {
                    if let user = authManager.currentUser {
                        LabeledContent("Email", value: user.email)
                        LabeledContent("Name", value: user.displayName)
                    } else {
                        Text("Signed in")
                    }
                    Button("Sign Out", role: .destructive) {
                        authManager.signOut()
                    }
                } else {
                    Text("Not signed in")
                }
            }

            Section("About") {
                LabeledContent("Version", value: "0.1.0")
            }
        }
    }
}

struct MobileNewFragmentView: View {
    @Environment(FragmentStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var sourceType: Fragment.SourceType = .note

    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $title)
                Picker("Type", selection: $sourceType) {
                    ForEach(Fragment.SourceType.allCases, id: \.self) { type in
                        Text(type.rawValue.capitalized).tag(type)
                    }
                }
                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                }
            }
            .navigationTitle("New Fragment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            try? await store.addFragment(
                                title: title,
                                content: content,
                                sourceType: sourceType
                            )
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty || content.isEmpty)
                }
            }
        }
    }
}
