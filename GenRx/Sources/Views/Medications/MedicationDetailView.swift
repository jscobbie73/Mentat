import SwiftUI
import SwiftData

struct MedicationDetailView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let medication: Medication

    @Query private var allLogs: [DoseLog]
    @State private var showEditForm = false

    private var recentLogs: [DoseLog] {
        allLogs
            .filter { $0.medicationID == medication.id }
            .sorted { ($0.scheduledTime) > ($1.scheduledTime) }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            List {
                Section {
                    detailRow("Type", medication.type.displayName)
                    if !medication.dosage.isEmpty {
                        detailRow("Dosage", medication.dosage)
                    }
                    detailRow("Schedule", medication.scheduleSummary)
                    if !medication.notes.isEmpty {
                        detailRow("Notes", medication.notes)
                    }
                }
                .listRowBackground(theme.surface)

                if medication.type == .injection && !medication.injectionSites.isEmpty {
                    Section("Injection Sites") {
                        InjectionSiteRotationView(medication: medication, logs: allLogs)
                    }
                    .listRowBackground(theme.surface)
                }

                if !recentLogs.isEmpty {
                    Section("Recent") {
                        ForEach(recentLogs) { log in
                            HStack {
                                Text(log.scheduledTime.formatted(date: .abbreviated, time: .shortened))
                                    .font(.themeCaption(theme))
                                    .foregroundStyle(theme.textSecondary)
                                Spacer()
                                DoseStatusBadge(status: log.status)
                                if let site = log.injectionSite {
                                    Text(site)
                                        .font(.themeCaption(theme))
                                        .foregroundStyle(theme.textSecondary)
                                }
                            }
                        }
                    }
                    .listRowBackground(theme.surface)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(medication.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEditForm = true }
                    .foregroundStyle(theme.primary)
            }
        }
        .sheet(isPresented: $showEditForm) {
            MedicationFormView(mode: .edit(medication))
        }
    }

    @ViewBuilder
    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.themeCaption(theme))
                .foregroundStyle(theme.textSecondary)
            Spacer()
            Text(value)
                .font(.themeBody(theme))
                .foregroundStyle(theme.textPrimary)
        }
    }
}
