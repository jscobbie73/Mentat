import SwiftUI

struct ThemeProvider: ViewModifier {
    let theme: AppTheme

    func body(content: Content) -> some View {
        ZStack {
            theme.background.ignoresSafeArea()
            themeDecoration
            content
        }
        .preferredColorScheme(theme.preferredColorScheme)
    }

    @ViewBuilder
    private var themeDecoration: some View {
        switch theme {
        case .synthwave:
            SynthwaveGridBackground()
        case .memphis:
            MemphisShapes()
        case .vhs:
            VHSScanlines()
        }
    }
}
