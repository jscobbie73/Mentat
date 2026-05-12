import SwiftUI

struct InjectionSiteRotationView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    let medication: Medication
    let logs: [DoseLog]

    @State private var confirmSiteOverride: String? = nil

    private var siteLogs: [String: DoseLog] {
        var result: [String: DoseLog] = [:]
        for log in logs where log.medicationID == medication.id {
            guard let site = log.injectionSite, log.status == .taken else { continue }
            if let existing = result[site] {
                if log.scheduledTime > existing.scheduledTime {
                    result[site] = log
                }
            } else {
                result[site] = log
            }
        }
        return result
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(medication.injectionSites.indices, id: \.self) { index in
                let site = medication.injectionSites[index]
                let isCurrent = index == medication.currentSiteIndex
                let isNext = index == (medication.currentSiteIndex + 1) % medication.injectionSites.count
                let lastLog = siteLogs[site]

                Button {
                    if !isCurrent { confirmSiteOverride = site }
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(isCurrent ? theme.primary : theme.textSecondary.opacity(0.2))
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(site)
                                    .font(.themeBody(theme))
                                    .foregroundStyle(isCurrent ? theme.primary : theme.textPrimary)

                                if isCurrent {
                                    Text("current")
                                        .font(.themeCaption(theme))
                                        .foregroundStyle(theme.primary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(theme.primary.opacity(0.15))
                                        .clipShape(Capsule())
                                } else if isNext && medication.injectionSites.count > 1 {
                                    Text("next")
                                        .font(.themeCaption(theme))
                                        .foregroundStyle(theme.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(theme.secondary.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }

                            if let log = lastLog, let takenTime = log.takenTime {
                                Text("Last: \(takenTime.relativeDateString())")
                                    .font(.themeCaption(theme))
                                    .foregroundStyle(theme.textSecondary)
                            } else {
                                Text("Never used")
                                    .font(.themeCaption(theme))
                                    .foregroundStyle(theme.textSecondary.opacity(0.5))
                            }
                        }

                        Spacer()

                        if !isCurrent {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(theme.textSecondary.opacity(0.4))
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
                .buttonStyle(.plain)

                if index < medication.injectionSites.count - 1 {
                    Divider()
                        .background(theme.primary.opacity(0.1))
                }
            }
        }
        .alert("Switch to \(confirmSiteOverride ?? "")?", isPresented: Binding(
            get: { confirmSiteOverride != nil },
            set: { if !$0 { confirmSiteOverride = nil } }
        )) {
            Button("Switch") {
                if let site = confirmSiteOverride,
                   let index = medication.injectionSites.firstIndex(of: site) {
                    medication.currentSiteIndex = index
                    try? modelContext.save()
                }
                confirmSiteOverride = nil
            }
            Button("Cancel", role: .cancel) { confirmSiteOverride = nil }
        } message: {
            Text("This will change the current injection site.")
        }
    }
}
