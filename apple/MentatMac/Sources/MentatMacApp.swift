import SwiftUI
import SwiftData

@main
struct MentatMacApp: App {
    let modelContainer: ModelContainer

    @State private var authManager = AuthManager()
    @State private var fragmentStore: FragmentStore

    init() {
        let schema = Schema([Fragment.self, Collection.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try! ModelContainer(for: schema, configurations: [config])
        self.modelContainer = container
        self._fragmentStore = State(initialValue: FragmentStore(modelContext: container.mainContext))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .environment(fragmentStore)
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
