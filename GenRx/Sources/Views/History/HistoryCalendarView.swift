import SwiftUI

struct HistoryCalendarView: View {
    @Environment(\.appTheme) private var theme
    let logs: [DoseLog]

    @State private var selectedDate = Date()

    private var logsForSelectedDate: [DoseLog] {
        logs.filter {
            Calendar.current.isDate($0.scheduledTime, inSameDayAs: selectedDate)
        }.sorted { $0.scheduledTime < $1.scheduledTime }
    }

    var body: some View {
        VStack(spacing: 0) {
            DatePicker(
                "Select Date",
                selection: $selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding(.horizontal)
            .colorScheme(theme.preferredColorScheme)
            .tint(theme.primary)

            Divider()
                .background(theme.primary.opacity(0.2))

            if logsForSelectedDate.isEmpty {
                Text("No doses logged for this day.")
                    .font(.themeBody(theme))
                    .foregroundStyle(theme.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                List(logsForSelectedDate) { log in
                    HistoryLogRowView(log: log)
                        .listRowBackground(theme.surface)
                        .listRowSeparatorTint(theme.primary.opacity(0.1))
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            Spacer()
        }
    }
}
