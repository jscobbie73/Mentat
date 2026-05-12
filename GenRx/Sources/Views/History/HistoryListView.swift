import SwiftUI

struct HistoryListView: View {
    @Environment(\.appTheme) private var theme
    let logs: [DoseLog]

    private var groupedLogs: [(String, [DoseLog])] {
        let grouped = Dictionary(grouping: logs) { log in
            log.scheduledTime.startOfDay.formatted(.dateTime.weekday(.wide).month().day())
        }
        return grouped.sorted { lhs, rhs in
            let lhsDate = logs.first { $0.scheduledTime.startOfDay.formatted(.dateTime.weekday(.wide).month().day()) == lhs.key }?.scheduledTime ?? Date.distantPast
            let rhsDate = logs.first { $0.scheduledTime.startOfDay.formatted(.dateTime.weekday(.wide).month().day()) == rhs.key }?.scheduledTime ?? Date.distantPast
            return lhsDate > rhsDate
        }
    }

    var body: some View {
        if logs.isEmpty {
            emptyState
        } else {
            List {
                ForEach(groupedLogs, id: \.0) { dateString, dayLogs in
                    Section(dateString) {
                        ForEach(dayLogs) { log in
                            HistoryLogRowView(log: log)
                                .listRowBackground(theme.surface)
                                .listRowSeparatorTint(theme.primary.opacity(0.1))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("No history yet. Check back after you've actually taken something.")
                .font(.themeBody(theme))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
    }
}

struct HistoryLogRowView: View {
    @Environment(\.appTheme) private var theme
    let log: DoseLog

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(log.medicationName)
                    .font(.themeBody(theme))
                    .foregroundStyle(theme.textPrimary)

                HStack(spacing: 6) {
                    Text(log.scheduledTime.timeString())
                        .font(.themeCaption(theme))
                        .foregroundStyle(theme.textSecondary)

                    if let site = log.injectionSite {
                        Text("· \(site)")
                            .font(.themeCaption(theme))
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            }

            Spacer()

            DoseStatusBadge(status: log.status)
        }
        .padding(.vertical, 4)
    }
}
