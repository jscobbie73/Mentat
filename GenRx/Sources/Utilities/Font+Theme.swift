import SwiftUI

extension Font {
    static func themeHeadline(_ theme: AppTheme) -> Font {
        switch theme {
        case .synthwave:
            return .system(.title3, design: .default, weight: .heavy)
        case .memphis:
            return .system(.title3, design: .rounded, weight: .heavy)
        case .vhs:
            return .system(.title3, design: .monospaced, weight: .bold)
        }
    }

    static func themeBody(_ theme: AppTheme) -> Font {
        switch theme {
        case .synthwave:
            return .system(.body, design: .default, weight: .medium)
        case .memphis:
            return .system(.body, design: .rounded, weight: .medium)
        case .vhs:
            return .system(.body, design: .monospaced, weight: .regular)
        }
    }

    static func themeCaption(_ theme: AppTheme) -> Font {
        switch theme {
        case .synthwave:
            return .system(.caption, design: .default, weight: .regular)
        case .memphis:
            return .system(.caption, design: .rounded, weight: .regular)
        case .vhs:
            return .system(.caption, design: .monospaced, weight: .regular)
        }
    }
}
