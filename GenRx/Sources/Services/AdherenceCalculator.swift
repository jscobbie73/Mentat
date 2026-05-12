import Foundation

struct MedicationAdherenceStat: Identifiable {
    let id: UUID
    let medicationName: String
    let colorHex: String
    let rate: Double
    let taken: Int
    let total: Int
}

enum AdherenceCalculator {
    static func adherenceRate(logs: [DoseLog], periodDays: Int) -> Double {
        let cutoff = Calendar.current.date(byAdding: .day, value: -periodDays, to: Date()) ?? Date()
        let relevant = logs.filter { $0.scheduledTime >= cutoff && ($0.status == .taken || $0.status == .missed) }
        guard !relevant.isEmpty else { return 0 }
        let taken = relevant.filter { $0.status == .taken }.count
        return Double(taken) / Double(relevant.count)
    }

    static func perMedicationBreakdown(logs: [DoseLog], medications: [Medication], periodDays: Int) -> [MedicationAdherenceStat] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -periodDays, to: Date()) ?? Date()
        return medications.map { med in
            let relevant = logs.filter {
                $0.medicationID == med.id &&
                $0.scheduledTime >= cutoff &&
                ($0.status == .taken || $0.status == .missed)
            }
            let taken = relevant.filter { $0.status == .taken }.count
            let rate = relevant.isEmpty ? 0.0 : Double(taken) / Double(relevant.count)
            return MedicationAdherenceStat(
                id: med.id,
                medicationName: med.name,
                colorHex: med.colorHex,
                rate: rate,
                taken: taken,
                total: relevant.count
            )
        }
    }
}
