import SwiftUI

/// iPad-optimized new fragment form with a wider layout and
/// drop target for dragging content in from other apps.
struct iPadNewFragmentView: View {
    @Environment(FragmentStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var content = ""
    @State private var sourceURLString = ""
    @State private var sourceType: Fragment.SourceType = .note
    @State private var isSaving = false
    @State private var isDropTargeted = false

    var body: some View {
        NavigationStack {
            HStack(alignment: .top, spacing: 0) {
                // Left: form fields
                Form {
                    Section("Details") {
                        TextField("Title", text: $title)
                            .font(.title3)

                        Picker("Type", selection: $sourceType) {
                            ForEach(Fragment.SourceType.allCases, id: \.self) { type in
                                Label(type.rawValue.capitalized, systemImage: iconForType(type))
                                    .tag(type)
                            }
                        }

                        TextField("Source URL (optional)", text: $sourceURLString)
                            .keyboardType(.URL)
                            .textContentType(.URL)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                }
                .frame(width: 320)

                Divider()

                // Right: content editor (full height)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    TextEditor(text: $content)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            if content.isEmpty && !isDropTargeted {
                                Text("Start typing, paste content, or drag text here...")
                                    .foregroundStyle(.tertiary)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Drop target for dragging text from other iPad apps
                .dropDestination(for: String.self) { items, _ in
                    if let dropped = items.first {
                        content += (content.isEmpty ? "" : "\n\n") + dropped
                        return true
                    }
                    return false
                } isTargeted: { targeted in
                    isDropTargeted = targeted
                }
                .overlay {
                    if isDropTargeted {
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.tint, lineWidth: 3)
                            .background(.tint.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                            .overlay {
                                Label("Drop content here", systemImage: "arrow.down.doc")
                                    .font(.title3)
                                    .foregroundStyle(.tint)
                            }
                            .allowsHitTesting(false)
                    }
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
                        save()
                    }
                    .disabled(title.isEmpty || content.isEmpty || isSaving)
                }
            }
            // Keyboard shortcut: Cmd+Return to save
            .onKeyPress(.return, phases: .down) { _ in
                if !title.isEmpty && !content.isEmpty {
                    save()
                    return .handled
                }
                return .ignored
            }
        }
        .presentationDetents([.large])
        .frame(minWidth: 700, minHeight: 500)
    }

    private func save() {
        guard !isSaving else { return }
        isSaving = true
        let url = URL(string: sourceURLString)
        Task {
            try? await store.addFragment(
                title: title,
                content: content,
                sourceURL: url,
                sourceType: sourceType
            )
            dismiss()
        }
    }

    private func iconForType(_ type: Fragment.SourceType) -> String {
        switch type {
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
