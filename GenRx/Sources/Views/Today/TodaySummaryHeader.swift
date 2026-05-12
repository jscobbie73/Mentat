import SwiftUI

struct TodaySummaryHeader: View {
    @Environment(\.appTheme) private var theme

    let done: Int
    let total: Int

    private var progress: Double {
        total == 0 ? 0 : Double(done) / Double(total)
    }

    private var summaryText: String {
        if total == 0 { return "Nothing due right now. Enjoy it." }
        if done == total { return "All done. See you tomorrow." }
        return "\(done) of \(total) done. Keep going."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(summaryText)
                .font(.themeBody(theme))
                .foregroundStyle(theme.textPrimary)
                .glitchText()

            if total > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(theme.surface)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(done == total ? theme.success : theme.primary)
                            .frame(width: geo.size.width * progress, height: 4)
                            .animation(.easeInOut, value: progress)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.vertical, 12)
    }
}
