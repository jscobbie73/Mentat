import SwiftUI

struct LogDoseSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    let dose: ScheduledDose
    let logService: DoseLogService?

    @State private var selectedSite: String = ""
    @State private var skipReason: String = ""
    @State private var showSkipReason = false
    @State private var prnTime = Date()

    init(dose: ScheduledDose, logService: DoseLogService?) {
        self.dose = dose
        self.logService = logService
        self._selectedSite = State(initialValue: dose.medication.currentInjectionSite ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text(dose.medication.name)
                            .font(.themeHeadline(theme))
                            .foregroundStyle(theme.textPrimary)

                        Text(dose.medication.dosage.isEmpty ? dose.medication.type.displayName : dose.medication.dosage)
                            .font(.themeBody(theme))
                            .foregroundStyle(theme.textSecondary)

                        if !dose.isPRN {
                            Text(dose.scheduledTime.timeString())
                                .font(.themeCaption(theme))
                                .foregroundStyle(theme.textSecondary)
                        }
                    }
                    .padding(.top, 8)

                    if dose.medication.type == .injection && !dose.medication.injectionSites.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Injection Site")
                                .font(.themeCaption(theme))
                                .foregroundStyle(theme.textSecondary)

                            Picker("Site", selection: $selectedSite) {
                                ForEach(dose.medication.injectionSites, id: \.self) { site in
                                    Text(site).tag(site)
                                }
                            }
                            .pickerStyle(.wheel)
                            .frame(height: 100)
                            .clipped()
                        }
                        .padding(.horizontal)
                    }

                    if dose.isPRN {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("When did you take it?")
                                .font(.themeCaption(theme))
                                .foregroundStyle(theme.textSecondary)

                            DatePicker("", selection: $prnTime, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .colorScheme(theme.preferredColorScheme)
                        }
                        .padding(.horizontal)
                    }

                    if showSkipReason {
                        TextField("Reason (optional)", text: $skipReason)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal)
                    }

                    VStack(spacing: 12) {
                        Button {
                            let site = dose.medication.type == .injection ? selectedSite : nil
                            let time = dose.isPRN ? prnTime : Date()
                            logService?.markTaken(dose: dose, site: site.flatMap { $0.isEmpty ? nil : $0 }, takenAt: time)
                            dismiss()
                        } label: {
                            Text("Mark Taken")
                                .font(.themeBody(theme))
                                .foregroundStyle(theme.background)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(theme.success)
                                .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius))
                        }

                        if !showSkipReason {
                            Button {
                                showSkipReason = true
                            } label: {
                                Text("Skip")
                                    .font(.themeBody(theme))
                                    .foregroundStyle(theme.textSecondary)
                            }
                        } else {
                            Button {
                                logService?.markSkipped(dose: dose, reason: skipReason)
                                dismiss()
                            } label: {
                                Text("Confirm Skip")
                                    .font(.themeBody(theme))
                                    .foregroundStyle(theme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(theme.surface)
                                    .clipShape(RoundedRectangle(cornerRadius: theme.cardCornerRadius))
                            }
                        }
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("cancel") { dismiss() }
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
