import SwiftUI

struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppTheme = .synthwave
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}
