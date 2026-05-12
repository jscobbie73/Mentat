import Foundation
import SwiftData

struct MedicationService {
    static func archive(_ medication: Medication, context: ModelContext) {
        medication.isActive = false
        try? context.save()
    }

    static func delete(_ medication: Medication, context: ModelContext) throws {
        let medID = medication.id
        let descriptor = FetchDescriptor<DoseLog>(predicate: #Predicate { $0.medicationID == medID })
        let logs = (try? context.fetch(descriptor)) ?? []
        for log in logs { context.delete(log) }
        context.delete(medication)
        try? context.save()
    }

    static func save(form: MedicationFormState, updating existing: Medication? = nil, context: ModelContext) -> Medication {
        let med = existing ?? Medication(name: form.name)
        med.name = form.name
        med.type = form.type
        med.dosage = form.dosage
        med.frequency = form.frequency
        med.timesOfDay = form.timesOfDay
        med.daysOfWeek = form.daysOfWeek
        med.intervalDays = form.intervalDays
        med.startDate = form.startDate
        med.injectionSites = form.injectionSites
        med.colorHex = form.colorHex
        med.notes = form.notes
        if existing == nil {
            context.insert(med)
        }
        try? context.save()
        return med
    }
}
