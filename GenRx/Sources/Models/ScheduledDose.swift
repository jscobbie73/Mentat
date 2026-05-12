import Foundation

struct ScheduledDose: Identifiable {
    let id: UUID
    let medication: Medication
    let scheduledTime: Date
    var status: DoseStatus
    var existingLog: DoseLog?

    var isPRN: Bool { medication.frequency == .asNeeded }
}
