import SwiftUI

struct MedicationRowView: View {
    @Environment(\.appTheme) private var theme
    let medication: Medication

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: medication.colorHex))
                .frame(width: 14, height: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text(medication.name)
                    .font(.themeBody(theme))
                    .foregroundStyle(theme.textPrimary)

                Text(medication.scheduleSummary)
                    .font(.themeCaption(theme))
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            Image(systemName: medication.type.icon)
                .foregroundStyle(theme.accent)
                .font(.caption)
        }
        .padding(.vertical, 6)
    }
}
