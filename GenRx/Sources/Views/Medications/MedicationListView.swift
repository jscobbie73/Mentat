import SwiftUI
import SwiftData

struct MedicationListView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<Medication> { $0.isActive }, sort: \Medication.name)
    private var activeMedications: [Medication]

    @Query(filter: #Predicate<Medication> { !$0.isActive }, sort: \Medication.name)
    private var archivedMedications: [Medication]

    @State private var showAddForm = false
    @State private var medicationToDelete: Medication?

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            List {
                if activeMedications.isEmpty {
                    Section {
                        Text("No medications yet. Add one with the + button.")
                            .font(.themeBody(theme))
                            .foregroundStyle(theme.textSecondary)
                            .listRowBackground(Color.clear)
                    }
                } else {
                    Section {
                        ForEach(activeMedications) { med in
                            NavigationLink(destination: MedicationDetailView(medication: med)) {
                                MedicationRowView(medication: med)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparatorTint(theme.primary.opacity(0.15))
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    medicationToDelete = med
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    MedicationService.archive(med, context: modelContext)
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                .tint(theme.secondary)
                            }
                        }
                    }
                }

                if !archivedMedications.isEmpty {
                    Section("archived") {
                        ForEach(archivedMedications) { med in
                            MedicationRowView(medication: med)
                                .foregroundStyle(theme.textSecondary)
                                .listRowBackground(Color.clear)
                                .swipeActions(edge: .trailing) {
                                    Button {
                                        med.isActive = true
                                        try? modelContext.save()
                                    } label: {
                                        Label("Restore", systemImage: "arrow.uturn.left")
                                    }
                                    .tint(theme.success)
                                }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("meds")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddForm = true } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(theme.primary)
                }
            }
        }
        .sheet(isPresented: $showAddForm) {
            MedicationFormView(mode: .add)
        }
        .alert("Delete \(medicationToDelete?.name ?? "")?", isPresented: Binding(get: { medicationToDelete != nil }, set: { if !$0 { medicationToDelete = nil } })) {
            Button("Delete", role: .destructive) {
                if let med = medicationToDelete {
                    try? MedicationService.delete(med, context: modelContext)
                    medicationToDelete = nil
                }
            }
            Button("Cancel", role: .cancel) { medicationToDelete = nil }
        } message: {
            Text("You won't be reminded anymore. Obviously.")
        }
    }
}
