import SwiftUI

/// iPad-optimized fragment detail view that uses the full width
/// with a two-column layout for content + AI insights side by side.
struct iPadFragmentDetailView: View {
    let fragment: Fragment

    @Environment(FragmentStore.self) private var store
    @Environment(CollectionStore.self) private var collectionStore
    @State private var connections: [ConnectionResult] = []
    @State private var suggestions: [String] = []
    @State private var insights: [InsightResponse] = []
    @State private var isLoadingConnections = false
    @State private var isLoadingSuggestions = false
    @State private var isLoadingInsights = false
    @State private var showDeleteConfirm = false
    @State private var showCollectionPicker = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, 32)
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                Divider()
                    .padding(.horizontal, 32)

                // Two-column layout: content on left, AI panel on right
                HStack(alignment: .top, spacing: 24) {
                    // Main content
                    VStack(alignment: .leading, spacing: 16) {
                        Text(fragment.content)
                            .font(.body)
                            .lineSpacing(4)
                            .textSelection(.enabled)

                        if let url = fragment.sourceURL {
                            Link(destination: url) {
                                Label(url.host ?? url.absoluteString, systemImage: "link")
                                    .font(.subheadline)
                            }
                            .padding(.top, 8)
                        }

                        // Insights section below content
                        if !insights.isEmpty {
                            insightsSection
                                .padding(.top, 16)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    // AI insights sidebar
                    VStack(alignment: .leading, spacing: 24) {
                        connectionsSection
                        suggestionsSection
                    }
                    .frame(width: 300)
                }
                .padding(32)
            }
        }
        .navigationTitle(fragment.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                ShareLink(
                    item: fragment.title + "\n\n" + fragment.content,
                    subject: Text(fragment.title)
                )

                Menu {
                    Button("Add to Collection", systemImage: "folder.badge.plus") {
                        showCollectionPicker = true
                    }
                    Button("Generate Insights", systemImage: "brain") {
                        Task { await generateInsights() }
                    }
                    Button("Refresh Connections", systemImage: "arrow.triangle.2.circlepath") {
                        Task { await loadConnections() }
                    }
                    Divider()
                    Button("Delete Fragment", systemImage: "trash", role: .destructive) {
                        showDeleteConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
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
        .sheet(isPresented: $showCollectionPicker) {
            AddToCollectionSheet(fragment: fragment)
        }
        .task {
            await loadConnections()
            await loadSuggestions()
            await loadInsights()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(fragment.title)
                .font(.largeTitle)
                .fontWeight(.bold)

            HStack(spacing: 16) {
                Label(fragment.sourceType.rawValue.capitalized, systemImage: "tag")
                    .font(.subheadline)
                    .foregroundStyle(.tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.tint.opacity(0.1), in: Capsule())

                Text(fragment.createdAt, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if fragment.createdAt != fragment.updatedAt {
                    Text("Updated \(fragment.updatedAt, style: .relative) ago")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }
        }
    }

    // MARK: - Insights

    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI Insights", systemImage: "brain")
                .font(.headline)

            ForEach(insights) { insight in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: insightIcon(for: insight.insightType))
                        .foregroundStyle(.tint)
                        .font(.caption)
                        .padding(.top, 2)
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

    private func insightIcon(for type: String) -> String {
        switch type {
        case "summary": return "doc.text"
        case "theme": return "paintpalette"
        case "suggestion": return "lightbulb"
        case "relatedTopic": return "arrow.triangle.branch"
        default: return "sparkle"
        }
    }

    // MARK: - Connections

    private var connectionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Connections", systemImage: "point.3.connected.trianglepath.dotted")
                .font(.headline)

            if isLoadingConnections {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if connections.isEmpty {
                Text("No connections discovered yet. Add more fragments for Mentat to find relationships.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(connections) { connection in
                    connectionCard(connection)
                }
            }
        }
    }

    private func connectionCard(_ connection: ConnectionResult) -> some View {
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
                similarityBadge(connection.similarity)
                Text(connection.sourceType.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
        .padding(12)
        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
    }

    private func similarityBadge(_ similarity: Float) -> some View {
        let percent = Int(similarity * 100)
        let color: Color = similarity > 0.9 ? .green : similarity > 0.8 ? .orange : .blue
        return Text("\(percent)% match")
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.12), in: Capsule())
    }

    // MARK: - Suggestions

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Further Reading", systemImage: "lightbulb")
                .font(.headline)

            if isLoadingSuggestions {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if suggestions.isEmpty {
                Text("Suggestions for related topics will appear after analysis.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(suggestions, id: \.self) { suggestion in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "arrow.right.circle")
                            .foregroundStyle(.tint)
                            .font(.caption)
                            .padding(.top, 2)
                        Text(suggestion)
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    // MARK: - Data loading

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
        isLoadingInsights = true
        defer { isLoadingInsights = false }
        insights = (try? await store.getInsights(for: fragment.id)) ?? []
    }

    private func generateInsights() async {
        isLoadingInsights = true
        defer { isLoadingInsights = false }
        if let generated = try? await store.generateInsights(for: fragment.id) {
            insights = generated
        }
    }
}
