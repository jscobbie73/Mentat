import SwiftUI

struct DoseStatusBadge: View {
    @Environment(\.appTheme) private var theme
    let status: DoseStatus

    var body: some View {
        Text(status.displayLabel)
            .font(.themeCaption(theme))
            .foregroundStyle(theme.statusColor(for: status))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(theme.statusColor(for: status).opacity(0.15))
            .clipShape(Capsule())
    }
}
