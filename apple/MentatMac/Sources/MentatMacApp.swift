import SwiftUI
import SwiftData

@main
struct MentatMacApp: App {
    let modelContainer: ModelContainer

    @State private var authManager = AuthManager()
    @State private var fragmentStore: FragmentStore
    @State private var collectionStore: CollectionStore

    init() {
        let schema = Schema([Fragment.self, Collection.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try! ModelContainer(for: schema, configurations: [config])
        self.modelContainer = container
        self._fragmentStore = State(initialValue: FragmentStore(modelContext: container.mainContext))
        self._collectionStore = State(initialValue: CollectionStore(modelContext: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            AuthGateView {
                ContentView()
            }
            .environment(authManager)
            .environment(fragmentStore)
            .environment(collectionStore)
        }
        .modelContainer(modelContainer)

        #if os(macOS)
        Settings {
            SettingsView()
                .environment(authManager)
        }

        MenuBarExtra("Mentat", systemImage: "brain.head.profile") {
            QuickCaptureMenu()
                .environment(fragmentStore)
        }
        #endif
    }
}
