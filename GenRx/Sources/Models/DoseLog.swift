import Foundation
import SwiftData

@Model
final class DoseLog {
    var id: UUID
    var medicationID: UUID
    var medicationName: String      // denormalized for history reads
    var medicationType: MedicationType
    var scheduledTime: Date
    var takenTime: Date?
    var status: DoseStatus
    var injectionSite: String?
    var notes: String

    init(
        id: UUID = UUID(),
        medicationID: UUID,
        medicationName: String,
        medicationType: MedicationType,
        scheduledTime: Date,
        takenTime: Date? = nil,
        status: DoseStatus = .pending,
        injectionSite: String? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.medicationID = medicationID
        self.medicationName = medicationName
        self.medicationType = medicationType
        self.scheduledTime = scheduledTime
        self.takenTime = takenTime
        self.status = status
        self.injectionSite = injectionSite
        self.notes = notes
    }

    var isEditableNow: Bool {
        guard let takenTime else { return status == .pending }
        return abs(takenTime.timeIntervalSinceNow) < 86400
    }
}
