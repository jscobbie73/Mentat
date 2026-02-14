import SwiftUI

/// Root view that switches layout based on device idiom:
/// - iPhone: Tab-based navigation
/// - iPad: Sidebar-driven NavigationSplitView with three columns
struct AdaptiveContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(FragmentStore.self) private var fragmentStore
    @Environment(CollectionStore.self) private var collectionStore

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                iPadContentView()
            } else {
                MobileContentView()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    try? await fragmentStore.sync()
                    try? await collectionStore.sync()
                }
            }
        }
    }
}
