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

// MARK: - Placeholder views

struct FragmentDetailView: View {
    let fragment: Fragment

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(fragment.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                HStack {
                    Label(fragment.sourceType.rawValue.capitalized, systemImage: "tag")
                    Spacer()
                    Text(fragment.createdAt, style: .date)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Divider()

                Text(fragment.content)
                    .font(.body)
                    .textSelection(.enabled)

                Divider()

                Text("Connections")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("AI-discovered connections will appear here.")
                    .foregroundStyle(.secondary)

                Text("Suggestions")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("AI suggestions for further reading will appear here.")
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle(fragment.title)
    }
}

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

struct SettingsView: View {
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
        }
        .frame(width: 400)
        .padding()
    }
}

struct QuickCaptureMenu: View {
    var body: some View {
        Button("New Note...") {}
            .keyboardShortcut("n", modifiers: [.command, .shift])
        Button("Paste from Clipboard") {}
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
