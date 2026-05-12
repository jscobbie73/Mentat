import SwiftUI

struct AdherenceStatsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTheme) private var theme

    let logs: [DoseLog]
    let medications: [Medication]

    @State private var exportURL: URL?
    @State private var showExportError = false

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                List {
                    overallSection(period: 7, label: "7-Day")
                    overallSection(period: 30, label: "30-Day")
                    overallSection(period: 3650, label: "All-Time")

                    if !medications.isEmpty {
                        perMedicationSection(period: 30)
                    }

                    Section {
                        Button {
                            exportCSV()
                        } label: {
                            Label("Export CSV", systemImage: "square.and.arrow.up")
                                .foregroundStyle(theme.primary)
                                .font(.themeBody(theme))
                        }
                    }
                    .listRowBackground(theme.surface)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .sheet(item: $exportURL) { url in
                ShareLink(item: url, subject: Text("GenRx Export"))
                    .presentationDetents([.medium])
            }
            .alert("Export failed", isPresented: $showExportError) {
                Button("OK", role: .cancel) {}
            }
        }
    }

    private func overallSection(period: Int, label: String) -> some View {
        let rate = AdherenceCalculator.adherenceRate(logs: logs, periodDays: period)
        return Section(label) {
            HStack {
                Text("Adherence")
                    .font(.themeBody(theme))
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                Text("\(Int(rate * 100))%")
                    .font(.themeHeadline(theme))
                    .foregroundStyle(rateColor(rate))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.surface)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(rateColor(rate))
                        .frame(width: geo.size.width * rate, height: 6)
                }
            }
            .frame(height: 6)
        }
        .listRowBackground(theme.surface)
    }

    private func perMedicationSection(period: Int) -> some View {
        let stats = AdherenceCalculator.perMedicationBreakdown(logs: logs, medications: medications, periodDays: period)
        return Section("Per Medication (30 Days)") {
            ForEach(stats) { stat in
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color(hex: stat.colorHex))
                        .frame(width: 10, height: 10)

                    Text(stat.medicationName)
                        .font(.themeBody(theme))
                        .foregroundStyle(theme.textPrimary)

                    Spacer()

                    if stat.total > 0 {
                        Text("\(Int(stat.rate * 100))%")
                            .font(.themeCaption(theme))
                            .foregroundStyle(rateColor(stat.rate))
                    } else {
                        Text("no data")
                            .font(.themeCaption(theme))
                            .foregroundStyle(theme.textSecondary)
                    }
                }
            }
        }
        .listRowBackground(theme.surface)
    }

    private func rateColor(_ rate: Double) -> Color {
        if rate >= 0.9 { return theme.success }
        if rate >= 0.7 { return theme.warning }
        return theme.primary
    }

    private func exportCSV() {
        do {
            let url = try CSVExporter.shareURL(logs: logs)
            exportURL = url
        } catch {
            showExportError = true
        }
    }
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}
