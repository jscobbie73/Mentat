import SwiftUI

enum AppTheme: String, CaseIterable {
    case synthwave
    case memphis
    case vhs

    var displayName: String {
        switch self {
        case .synthwave: return "Synthwave"
        case .memphis: return "Memphis"
        case .vhs: return "VHS"
        }
    }

    var tagline: String {
        switch self {
        case .synthwave: return "Tron called. It wants its pills back."
        case .memphis: return "Geometric. Chaotic. Medicated."
        case .vhs: return "Be kind, rewind, and take your meds."
        }
    }

    // MARK: - Colors

    var background: Color {
        switch self {
        case .synthwave: return Color(hex: "#0A0014")
        case .memphis: return Color(hex: "#FAFAFA")
        case .vhs: return Color(hex: "#0D0D0D")
        }
    }

    var surface: Color {
        switch self {
        case .synthwave: return Color(hex: "#12001F")
        case .memphis: return Color(hex: "#FFFFFF")
        case .vhs: return Color(hex: "#161616")
        }
    }

    var primary: Color {
        switch self {
        case .synthwave: return Color(hex: "#FF2D78")
        case .memphis: return Color(hex: "#E63946")
        case .vhs: return Color(hex: "#00FF41")
        }
    }

    var secondary: Color {
        switch self {
        case .synthwave: return Color(hex: "#00F5FF")
        case .memphis: return Color(hex: "#2196F3")
        case .vhs: return Color(hex: "#FF6B35")
        }
    }

    var accent: Color {
        switch self {
        case .synthwave: return Color(hex: "#BF5FFF")
        case .memphis: return Color(hex: "#FF9800")
        case .vhs: return Color(hex: "#FFFF00")
        }
    }

    var success: Color {
        switch self {
        case .synthwave: return Color(hex: "#00FF9F")
        case .memphis: return Color(hex: "#4CAF50")
        case .vhs: return Color(hex: "#00FF41")
        }
    }

    var warning: Color {
        switch self {
        case .synthwave: return Color(hex: "#FFD600")
        case .memphis: return Color(hex: "#FF9800")
        case .vhs: return Color(hex: "#FFFF00")
        }
    }

    var textPrimary: Color {
        switch self {
        case .synthwave: return Color(hex: "#FFFFFF")
        case .memphis: return Color(hex: "#1A1A1A")
        case .vhs: return Color(hex: "#E8E8E8")
        }
    }

    var textSecondary: Color {
        switch self {
        case .synthwave: return Color(hex: "#FFFFFF").opacity(0.6)
        case .memphis: return Color(hex: "#1A1A1A").opacity(0.6)
        case .vhs: return Color(hex: "#E8E8E8").opacity(0.6)
        }
    }

    // MARK: - Card Style

    var cardBorderWidth: CGFloat {
        switch self {
        case .synthwave: return 1
        case .memphis: return 2.5
        case .vhs: return 1
        }
    }

    var cardCornerRadius: CGFloat {
        switch self {
        case .synthwave: return 12
        case .memphis: return 2
        case .vhs: return 4
        }
    }

    // MARK: - Typography

    var headingWeight: Font.Weight {
        switch self {
        case .synthwave: return .heavy
        case .memphis: return .heavy
        case .vhs: return .bold
        }
    }

    var useMonospaced: Bool { self == .vhs }

    // MARK: - Color Scheme

    var isAlwaysDark: Bool { self == .synthwave || self == .vhs }

    var preferredColorScheme: ColorScheme {
        switch self {
        case .synthwave, .vhs: return .dark
        case .memphis: return .light
        }
    }

    // MARK: - Status Colors

    func statusColor(for status: DoseStatus) -> Color {
        switch status {
        case .pending: return warning
        case .taken: return success
        case .skipped: return textSecondary
        case .missed: return primary
        }
    }

    // MARK: - Preset Palette Swatches (for color picker in med form)

    static var presetColors: [String] {
        ["#FF2D78", "#00F5FF", "#BF5FFF", "#00FF9F", "#FFD600",
         "#E63946", "#2196F3", "#FF9800", "#4CAF50",
         "#00FF41", "#FF6B35", "#FFFF00"]
    }
}
