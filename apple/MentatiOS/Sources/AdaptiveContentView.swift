import SwiftUI

/// Root view that switches layout based on device idiom:
/// - iPhone: Tab-based navigation
/// - iPad: Sidebar-driven NavigationSplitView with three columns
struct AdaptiveContentView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            iPadContentView()
        } else {
            MobileContentView()
        }
    }
}
