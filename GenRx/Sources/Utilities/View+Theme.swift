import SwiftUI

extension View {
    func themedCard() -> some View {
        modifier(ThemedCardModifier())
    }

    func glowEffect(color: Color) -> some View {
        self
            .shadow(color: color.opacity(0.7), radius: 6)
            .shadow(color: color.opacity(0.4), radius: 12)
    }
}

private struct ThemedCardModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: theme.cardCornerRadius)
                    .stroke(theme.primary.opacity(0.4), lineWidth: theme.cardBorderWidth)
            )
            .modifier(GlowModifier(theme: theme))
    }
}

private struct GlowModifier: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        if theme == .synthwave {
            content.glowEffect(color: theme.primary)
        } else {
            content
        }
    }
}
