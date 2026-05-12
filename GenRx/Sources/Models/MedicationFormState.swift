import Foundation
import Observation

@Observable
final class MedicationFormState {
    var name: String = ""
    var type: MedicationType = .pill
    var dosage: String = ""
    var frequency: FrequencyType = .daily
    var timesOfDay: [String] = ["08:00"]
    var daysOfWeek: [Int] = []
    var intervalDays: Int = 7
    var startDate: Date = Date()
    var injectionSites: [String] = []
    var colorHex: String = "#FF2D78"
    var notes: String = ""

    init() {}

    init(from medication: Medication) {
        self.name = medication.name
        self.type = medication.type
        self.dosage = medication.dosage
        self.frequency = medication.frequency
        self.timesOfDay = medication.timesOfDay.isEmpty ? ["08:00"] : medication.timesOfDay
        self.daysOfWeek = medication.daysOfWeek
        self.intervalDays = medication.intervalDays
        self.startDate = medication.startDate
        self.injectionSites = medication.injectionSites
        self.colorHex = medication.colorHex
        self.notes = medication.notes
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        (frequency == .asNeeded || !timesOfDay.isEmpty)
    }

    var validationMessage: String? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            return "Name is required."
        }
        if frequency != .asNeeded && timesOfDay.isEmpty {
            return "Add at least one time of day."
        }
        return nil
    }
}
