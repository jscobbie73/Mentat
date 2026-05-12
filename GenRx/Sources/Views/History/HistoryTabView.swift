import SwiftUI
import SwiftData

struct HistoryTabView: View {
    @Environment(\.appTheme) private var theme

    @Query(filter: #Predicate<Medication> { $0.isActive })
    private var medications: [Medication]

    @Query(sort: \DoseLog.scheduledTime, order: .reverse)
    private var allLogs: [DoseLog]

    @State private var selectedTab = 0
    @State private var filterMedicationID: UUID? = nil
    @State private var showStats = false

    private var filteredLogs: [DoseLog] {
        guard let id = filterMedicationID else { return allLogs }
        return allLogs.filter { $0.medicationID == id }
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Picker("View", selection: $selectedTab) {
                    Text("List").tag(0)
                    Text("Calendar").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                if !medications.isEmpty {
                    medicationFilterBar
                }

                if selectedTab == 0 {
                    HistoryListView(logs: filteredLogs)
                } else {
                    HistoryCalendarView(logs: filteredLogs)
                }
            }
        }
        .navigationTitle("history")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showStats = true
                } label: {
                    Image(systemName: "chart.bar")
                        .foregroundStyle(theme.primary)
                }
            }
        }
        .sheet(isPresented: $showStats) {
            AdherenceStatsView(logs: allLogs, medications: medications)
        }
    }

    private var medicationFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(label: "All", id: nil)
                ForEach(medications) { med in
                    filterChip(label: med.name, id: med.id, hex: med.colorHex)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
    }

    @ViewBuilder
    private func filterChip(label: String, id: UUID?, hex: String? = nil) -> some View {
        let isSelected = filterMedicationID == id
        Button {
            filterMedicationID = id
        } label: {
            HStack(spacing: 4) {
                if let hex {
                    Circle().fill(Color(hex: hex)).frame(width: 8, height: 8)
                }
                Text(label)
                    .font(.themeCaption(theme))
            }
            .foregroundStyle(isSelected ? theme.background : theme.textPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? theme.primary : theme.surface)
            .clipShape(Capsule())
        }
    }
}
