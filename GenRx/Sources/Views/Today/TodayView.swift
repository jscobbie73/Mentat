import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    @Query(filter: #Predicate<Medication> { $0.isActive })
    private var medications: [Medication]

    @Query private var allLogs: [DoseLog]

    @State private var selectedDose: ScheduledDose?
    @State private var logService: DoseLogService?

    private var todayLogs: [DoseLog] {
        let start = Date().startOfDay
        let end = Date().endOfDay
        return allLogs.filter { $0.scheduledTime >= start && $0.scheduledTime <= end }
    }

    private var scheduledDoses: [ScheduledDose] {
        ScheduleEngine.dosesForToday(medications: medications, existingLogs: todayLogs)
    }

    private var takenCount: Int {
        scheduledDoses.filter { $0.status == .taken || $0.status == .skipped }.count
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                TodaySummaryHeader(done: takenCount, total: scheduledDoses.count)
                    .padding(.horizontal)
                    .padding(.top, 8)

                if scheduledDoses.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(scheduledDoses) { dose in
                            DoseCardView(dose: dose) {
                                selectedDose = dose
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    logService?.markTaken(dose: dose, site: dose.medication.currentInjectionSite)
                                } label: {
                                    Label("Take", systemImage: "checkmark")
                                }
                                .tint(theme.success)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    logService?.markSkipped(dose: dose)
                                } label: {
                                    Label("Skip", systemImage: "xmark")
                                }
                                .tint(theme.secondary)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparatorTint(theme.primary.opacity(0.15))
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("today")
        .navigationBarTitleDisplayMode(.large)
        .sheet(item: $selectedDose) { dose in
            LogDoseSheet(dose: dose, logService: logService)
        }
        .onAppear {
            if logService == nil {
                logService = DoseLogService(modelContext: modelContext)
            }
            logService?.auditMissedDoses(existingLogs: allLogs)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                logService?.auditMissedDoses(existingLogs: allLogs)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Text(takenCount > 0 ? "All done. See you tomorrow." : "Nothing due right now. Enjoy it.")
                .font(.themeBody(theme))
                .foregroundStyle(theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }
}
