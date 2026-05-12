import SwiftUI

struct DoseCardView: View {
    @Environment(\.appTheme) private var theme
    let dose: ScheduledDose
    let onTap: () -> Void

    var body: some View {
        Button(action: { onTap() }) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: dose.medication.colorHex))
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(dose.medication.name)
                        .font(.themeBody(theme))
                        .foregroundStyle(theme.textPrimary)

                    Text(dose.medication.dosage.isEmpty ? dose.medication.type.displayName : "\(dose.medication.dosage) · \(dose.medication.type.displayName)")
                        .font(.themeCaption(theme))
                        .foregroundStyle(theme.textSecondary)

                    if let site = dose.medication.currentInjectionSite {
                        Label(site, systemImage: "mappin.circle")
                            .font(.themeCaption(theme))
                            .foregroundStyle(theme.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(dose.scheduledTime.timeString())
                        .font(.themeCaption(theme))
                        .foregroundStyle(theme.textSecondary)

                    Image(systemName: dose.medication.type.icon)
                        .foregroundStyle(theme.accent)
                        .font(.caption)

                    DoseStatusBadge(status: dose.status)
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .themedCard()
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
