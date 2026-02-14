import SwiftUI

struct ContentView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(FragmentStore.self) private var store

    @State private var searchText = ""
    @State private var selectedFragment: Fragment?
    @State private var showingNewFragment = false

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            if let fragment = selectedFragment {
                FragmentDetailView(fragment: fragment)
            } else {
                ContentUnavailableView(
                    "Select a Fragment",
                    systemImage: "doc.text",
                    description: Text("Choose a fragment from the sidebar or create a new one.")
                )
            }
        }
        .searchable(text: $searchText, prompt: "Search your knowledge...")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingNewFragment = true }) {
                    Label("New Fragment", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingNewFragment) {
            NewFragmentView()
        }
    }

    private var sidebar: some View {
        List(store.fragments, selection: $selectedFragment) { fragment in
            NavigationLink(value: fragment) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(fragment.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(fragment.content)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Text(fragment.createdAt, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Mentat")
    }
}

// MARK: - Fragment Detail (Mac)

struct FragmentDetailView: View {
    let fragment: Fragment

    @Environment(FragmentStore.self) private var store
    @State private var connections: [ConnectionResult] = []
    @State private var suggestions: [String] = []
    @State private var insights: [InsightResponse] = []
    @State private var isLoadingConnections = false
    @State private var isLoadingSuggestions = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text(fragment.title)
                    .font(.largeTitle)
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
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Divider()

                // Content
                Text(fragment.content)
                    .font(.body)
                    .textSelection(.enabled)
                    .lineSpacing(4)

                if let url = fragment.sourceURL {
                    Link(destination: url) {
                        Label(url.host ?? url.absoluteString, systemImage: "link")
                            .font(.subheadline)
                    }
                }

                // Insights
                if !insights.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 12) {
                        Label("AI Insights", systemImage: "brain")
                            .font(.title2)
                            .fontWeight(.semibold)

                        ForEach(insights) { insight in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "sparkle")
                                    .foregroundStyle(.tint)
                                    .font(.caption)
                                    .padding(.top, 3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(insight.insightType.capitalized)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.secondary)
                                    Text(insight.content)
                                        .font(.subheadline)
                                }
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                Divider()

                // Connections
                VStack(alignment: .leading, spacing: 12) {
                    Label("Connections", systemImage: "point.3.connected.trianglepath.dotted")
                        .font(.title2)
                        .fontWeight(.semibold)

                    if isLoadingConnections {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if connections.isEmpty {
                        Text("No connections discovered yet. Add more fragments for Mentat to find relationships.")
                            .foregroundStyle(.secondary)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(connections) { connection in
                                macConnectionCard(connection)
                            }
                        }
                    }
                }

                Divider()

                // Suggestions
                VStack(alignment: .leading, spacing: 12) {
                    Label("Further Reading", systemImage: "lightbulb")
                        .font(.title2)
                        .fontWeight(.semibold)

                    if isLoadingSuggestions {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    } else if suggestions.isEmpty {
                        Text("Suggestions for related topics will appear after analysis.")
                            .foregroundStyle(.secondary)
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
            .padding(24)
        }
        .navigationTitle(fragment.title)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("Generate Insights", systemImage: "brain") {
                    Task {
                        if let generated = try? await store.generateInsights(for: fragment.id) {
                            insights = generated
                        }
                    }
                }

                Button("Refresh", systemImage: "arrow.triangle.2.circlepath") {
                    Task {
                        await loadConnections()
                        await loadSuggestions()
                    }
                }

                Button("Delete", systemImage: "trash", role: .destructive) {
                    showDeleteConfirm = true
                }
            }
        }
        .confirmationDialog("Delete Fragment?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task { try? await store.deleteFragment(fragment) }
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .task {
            await loadConnections()
            await loadSuggestions()
            await loadInsights()
        }
    }

    private func macConnectionCard(_ connection: ConnectionResult) -> some View {
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
                    .lineLimit(3)
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

                Text(connection.sourceType.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
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

    private func loadInsights() async {
        insights = (try? await store.getInsights(for: fragment.id)) ?? []
    }
}

// MARK: - New Fragment

struct NewFragmentView: View {
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
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("New Fragment")
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
        .frame(minWidth: 500, minHeight: 400)
    }
}

// MARK: - Settings

struct SettingsView: View {
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
        }
        .frame(width: 400)
        .padding()
    }
}

// MARK: - Menu Bar Quick Capture

struct QuickCaptureMenu: View {
    @Environment(FragmentStore.self) private var store

    var body: some View {
        Button("New Note...") {
            NSWorkspace.shared.open(URL(string: "mentat://new")!)
        }
        .keyboardShortcut("n", modifiers: [.command, .shift])

        Button("Paste from Clipboard") {
            if let text = NSPasteboard.general.string(forType: .string), !text.isEmpty {
                Task {
                    let title = String(text.prefix(80))
                    try? await store.addFragment(
                        title: title,
                        content: text,
                        sourceType: .note
                    )
                }
            }
        }

        Divider()

        Button("Open Mentat") {
            NSWorkspace.shared.open(URL(string: "mentat://")!)
        }

        Divider()

        Button("Quit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
