import SwiftUI
import SwiftData

enum FormMode {
    case add
    case edit(Medication)
}

struct MedicationFormView: View {
    @Environment(\.appTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let mode: FormMode

    @State private var formState: MedicationFormState

    init(mode: FormMode) {
        self.mode = mode
        switch mode {
        case .add:
            _formState = State(initialValue: MedicationFormState())
        case .edit(let med):
            _formState = State(initialValue: MedicationFormState(from: med))
        }
    }

    var title: String {
        switch mode {
        case .add: return "Add Medication"
        case .edit: return "Edit Medication"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                Form {
                    basicInfoSection
                    scheduleSection
                    if formState.type == .injection {
                        injectionSitesSection
                    }
                    appearanceSection
                    notesSection
                }
                .scrollContentBackground(.hidden)
                .tint(theme.primary)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(theme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .foregroundStyle(formState.isValid ? theme.primary : theme.textSecondary)
                        .disabled(!formState.isValid)
                }
            }
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        Section("Basics") {
            TextField("Name", text: $formState.name)
                .font(.themeBody(theme))

            Picker("Type", selection: $formState.type) {
                ForEach(MedicationType.allCases, id: \.self) { type in
                    Label(type.displayName, systemImage: type.icon).tag(type)
                }
            }

            TextField("Dosage (e.g. 10mg)", text: $formState.dosage)
                .font(.themeBody(theme))
        }
        .listRowBackground(theme.surface)
    }

    private var scheduleSection: some View {
        Section("Schedule") {
            Picker("Frequency", selection: $formState.frequency) {
                ForEach(FrequencyType.allCases, id: \.self) { freq in
                    Text(freq.displayName).tag(freq)
                }
            }

            switch formState.frequency {
            case .daily:
                timesOfDayRows
            case .weekly:
                daysOfWeekRows
                timesOfDayRows
            case .everyNDays:
                Stepper("Every \(formState.intervalDays) days", value: $formState.intervalDays, in: 1...365)
                    .font(.themeBody(theme))
                DatePicker("Start Date", selection: $formState.startDate, displayedComponents: .date)
                timesOfDayRows
            case .asNeeded:
                Text("No automatic reminders. Log manually.")
                    .font(.themeCaption(theme))
                    .foregroundStyle(theme.textSecondary)
            }
        }
        .listRowBackground(theme.surface)
    }

    @ViewBuilder
    private var timesOfDayRows: some View {
        ForEach(formState.timesOfDay.indices, id: \.self) { index in
            TimePicker(timeString: $formState.timesOfDay[index])
        }
        .onDelete { formState.timesOfDay.remove(atOffsets: $0) }

        Button {
            formState.timesOfDay.append("12:00")
        } label: {
            Label("Add Time", systemImage: "plus.circle")
                .foregroundStyle(theme.primary)
                .font(.themeBody(theme))
        }
    }

    @ViewBuilder
    private var daysOfWeekRows: some View {
        let weekdays = Calendar.current.shortWeekdaySymbols
        ForEach(1...7, id: \.self) { day in
            let isSelected = formState.daysOfWeek.contains(day)
            Button {
                if isSelected {
                    formState.daysOfWeek.removeAll { $0 == day }
                } else {
                    formState.daysOfWeek.append(day)
                    formState.daysOfWeek.sort()
                }
            } label: {
                HStack {
                    Text(weekdays[day - 1])
                        .font(.themeBody(theme))
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(theme.primary)
                    }
                }
            }
        }
    }

    private var injectionSitesSection: some View {
        Section("Injection Sites") {
            ForEach(formState.injectionSites.indices, id: \.self) { index in
                TextField("Site name", text: $formState.injectionSites[index])
                    .font(.themeBody(theme))
            }
            .onDelete { formState.injectionSites.remove(atOffsets: $0) }
            .onMove { formState.injectionSites.move(fromOffsets: $0, toOffset: $1) }

            Button {
                formState.injectionSites.append("")
            } label: {
                Label("Add Site", systemImage: "plus.circle")
                    .foregroundStyle(theme.primary)
                    .font(.themeBody(theme))
            }
        }
        .listRowBackground(theme.surface)
    }

    private var appearanceSection: some View {
        Section("Color") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(AppTheme.presetColors, id: \.self) { hex in
                        Button {
                            formState.colorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: formState.colorHex == hex ? 2 : 0)
                                )
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .listRowBackground(theme.surface)
    }

    private var notesSection: some View {
        Section("Notes") {
            TextEditor(text: $formState.notes)
                .font(.themeBody(theme))
                .frame(minHeight: 80)
                .foregroundStyle(theme.textPrimary)
        }
        .listRowBackground(theme.surface)
    }

    // MARK: - Save

    private func save() {
        switch mode {
        case .add:
            _ = MedicationService.save(form: formState, context: modelContext)
        case .edit(let med):
            _ = MedicationService.save(form: formState, updating: med, context: modelContext)
        }
        dismiss()
    }
}

// MARK: - TimePicker helper

private struct TimePicker: View {
    @Binding var timeString: String

    private var binding: Binding<Date> {
        Binding {
            Date.fromTimeString(timeString) ?? Date()
        } set: { date in
            let h = Calendar.current.component(.hour, from: date)
            let m = Calendar.current.component(.minute, from: date)
            timeString = String(format: "%02d:%02d", h, m)
        }
    }

    var body: some View {
        DatePicker("Time", selection: binding, displayedComponents: .hourAndMinute)
    }
}
