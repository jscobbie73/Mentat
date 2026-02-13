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
    }
}

// MARK: - Placeholder views for iOS

struct MobileFragmentDetailView: View {
    let fragment: Fragment

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(fragment.title)
                    .font(.title)
                    .fontWeight(.bold)

                Label(fragment.sourceType.rawValue.capitalized, systemImage: "tag")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Divider()

                Text(fragment.content)
                    .font(.body)
                    .textSelection(.enabled)

                Divider()

                Section {
                    Text("AI-discovered connections will appear here.")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Connections")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

                Section {
                    Text("AI suggestions for further reading will appear here.")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Suggestions")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
            }
            .padding()
        }
        .navigationTitle(fragment.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DiscoverView: View {
    var body: some View {
        ContentUnavailableView(
            "Discover Connections",
            systemImage: "sparkles",
            description: Text("As you add more fragments, Mentat will surface connections and insights here.")
        )
    }
}

struct CollectionsView: View {
    var body: some View {
        ContentUnavailableView(
            "No Collections Yet",
            systemImage: "folder",
            description: Text("Create collections to organize your fragments.")
        )
    }
}

struct MobileSettingsView: View {
    @Environment(AuthManager.self) private var authManager

    var body: some View {
        Form {
            Section("Account") {
                if authManager.isAuthenticated {
                    Text("Signed in")
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
