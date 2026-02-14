import SwiftUI
import SwiftData

@main
struct MentatiOSApp: App {
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
            AdaptiveContentView()
                .environment(authManager)
                .environment(fragmentStore)
        }
        .modelContainer(modelContainer)
    }
}
