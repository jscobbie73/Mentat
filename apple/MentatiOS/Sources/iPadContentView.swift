import SwiftUI

/// Sidebar sections for iPad navigation.
enum iPadSection: String, CaseIterable, Identifiable {
    case library = "Library"
    case discover = "Discover"
    case collections = "Collections"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .library: return "books.vertical"
        case .discover: return "sparkles"
        case .collections: return "folder"
        case .settings: return "gear"
        }
    }
}

/// iPad-optimized three-column layout with sidebar, list, and detail panes.
struct iPadContentView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(FragmentStore.self) private var store

    @State private var selectedSection: iPadSection? = .library
    @State private var selectedFragment: Fragment?
    @State private var searchText = ""
    @State private var showingNewFragment = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } content: {
            contentColumn
        } detail: {
            detailColumn
        }
        .navigationSplitViewStyle(.balanced)
        .searchable(text: $searchText, prompt: "Search your knowledge...")
        .sheet(isPresented: $showingNewFragment) {
            iPadNewFragmentView()
        }
        // iPad keyboard shortcuts
        .keyboardShortcut("n", modifiers: .command)
        .onKeyPress(.init("n"), phases: .down) { _ in
            showingNewFragment = true
            return .handled
        }
    }

    // MARK: - Sidebar (column 1)

    private var sidebar: some View {
        List(iPadSection.allCases, selection: $selectedSection) { section in
            Label(section.rawValue, systemImage: section.icon)
        }
        .navigationTitle("Mentat")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewFragment = true }) {
                    Image(systemName: "plus")
                }
            }
        }
    }

    // MARK: - Content list (column 2)

    @ViewBuilder
    private var contentColumn: some View {
        switch selectedSection {
        case .library:
            iPadFragmentList(
                fragments: filteredFragments,
                selectedFragment: $selectedFragment
            )
        case .discover:
            iPadDiscoverList(
                fragments: store.fragments,
                selectedFragment: $selectedFragment
            )
        case .collections:
            iPadCollectionsList()
        case .settings:
            MobileSettingsView()
        case .none:
            Text("Select a section")
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Detail (column 3)

    @ViewBuilder
    private var detailColumn: some View {
        if let fragment = selectedFragment {
            iPadFragmentDetailView(fragment: fragment)
        } else {
            ContentUnavailableView(
                "Select a Fragment",
                systemImage: "doc.text",
                description: Text("Choose a fragment from the list, or create a new one with \(Image(systemName: "command")) N.")
            )
        }
    }

    // MARK: - Filtering

    private var filteredFragments: [Fragment] {
        if searchText.isEmpty {
            return store.fragments
        }
        let query = searchText.lowercased()
        return store.fragments.filter {
            $0.title.lowercased().contains(query) ||
            $0.content.lowercased().contains(query)
        }
    }
}

// MARK: - iPad Fragment List

struct iPadFragmentList: View {
    let fragments: [Fragment]
    @Binding var selectedFragment: Fragment?

    var body: some View {
        List(fragments, selection: $selectedFragment) { fragment in
            NavigationLink(value: fragment) {
                iPadFragmentRow(fragment: fragment)
            }
        }
        .navigationTitle("Library")
        .overlay {
            if fragments.isEmpty {
                ContentUnavailableView(
                    "No Fragments Yet",
                    systemImage: "doc.text",
                    description: Text("Tap + to create your first fragment.")
                )
            }
        }
    }
}

struct iPadFragmentRow: View {
    let fragment: Fragment

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(fragment.title)
                .font(.headline)
                .lineLimit(1)
            Text(fragment.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
            HStack {
                Label(fragment.sourceType.rawValue.capitalized, systemImage: sourceTypeIcon)
                    .font(.caption)
                    .foregroundStyle(.tint)
                Spacer()
                Text(fragment.createdAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 6)
        // iPad drag to share fragments
        .draggable(fragment.title + "\n\n" + fragment.content)
    }

    private var sourceTypeIcon: String {
        switch fragment.sourceType {
        case .note: return "note.text"
        case .highlight: return "highlighter"
        case .bookmark: return "bookmark"
        case .article: return "doc.richtext"
        case .image: return "photo"
        case .file: return "doc"
        case .share: return "square.and.arrow.down"
        }
    }
}

// MARK: - iPad Discover List

struct iPadDiscoverList: View {
    let fragments: [Fragment]
    @Binding var selectedFragment: Fragment?

    @State private var insights: [InsightResponse] = []
    @State private var isLoading = false

    var body: some View {
        List {
            if !insights.isEmpty {
                Section("AI Insights") {
                    ForEach(insights) { insight in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "sparkle")
                                    .foregroundStyle(.tint)
                                    .font(.caption)
                                Text(insight.insightType.capitalized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.tint)
                            }
                            Text(insight.content)
                                .font(.subheadline)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            Section("Recent Fragments") {
                if fragments.isEmpty {
                    ContentUnavailableView(
                        "No Fragments Yet",
                        systemImage: "sparkles",
                        description: Text("Add fragments for Mentat to discover connections.")
                    )
                } else {
                    ForEach(fragments) { fragment in
                        NavigationLink(value: fragment) {
                            iPadFragmentRow(fragment: fragment)
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Discover")
        .overlay {
            if isLoading && insights.isEmpty && fragments.isEmpty {
                ProgressView("Loading insights...")
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

// MARK: - iPad Collections List

struct iPadCollectionsList: View {
    @Environment(CollectionStore.self) private var collectionStore
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
                List(collectionStore.collections) { collection in
                    NavigationLink {
                        iPadCollectionDetailView(collection: collection)
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
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Collections")
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
    }
}

struct iPadCollectionDetailView: View {
    let collection: Collection
    @Environment(CollectionStore.self) private var collectionStore

    var body: some View {
        List {
            if collection.fragments.isEmpty {
                ContentUnavailableView(
                    "Empty Collection",
                    systemImage: "folder",
                    description: Text("Add fragments from the fragment detail view.")
                )
            } else {
                ForEach(collection.fragments) { fragment in
                    iPadFragmentRow(fragment: fragment)
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
