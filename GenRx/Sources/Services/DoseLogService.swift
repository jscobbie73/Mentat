import Foundation
import SwiftData
import Observation

@Observable
final class DoseLogService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func markTaken(dose: ScheduledDose, site: String? = nil, takenAt: Date = Date()) {
        if let log = dose.existingLog {
            log.status = .taken
            log.takenTime = takenAt
            log.injectionSite = site ?? log.injectionSite
        } else {
            let log = DoseLog(
                medicationID: dose.medication.id,
                medicationName: dose.medication.name,
                medicationType: dose.medication.type,
                scheduledTime: dose.scheduledTime,
                takenTime: takenAt,
                status: .taken,
                injectionSite: site
            )
            modelContext.insert(log)
        }
        if dose.medication.type == .injection {
            dose.medication.advanceSite()
        }
        try? modelContext.save()
        Haptics.success()
    }

    func markSkipped(dose: ScheduledDose, reason: String = "") {
        if let log = dose.existingLog {
            log.status = .skipped
            log.notes = reason
        } else {
            let log = DoseLog(
                medicationID: dose.medication.id,
                medicationName: dose.medication.name,
                medicationType: dose.medication.type,
                scheduledTime: dose.scheduledTime,
                status: .skipped,
                notes: reason
            )
            modelContext.insert(log)
        }
        try? modelContext.save()
        Haptics.tap()
    }

    func markMissed(log: DoseLog) {
        log.status = .missed
        try? modelContext.save()
    }

    func logPRN(medication: Medication, takenAt: Date = Date(), site: String? = nil) {
        let log = DoseLog(
            medicationID: medication.id,
            medicationName: medication.name,
            medicationType: medication.type,
            scheduledTime: takenAt,
            takenTime: takenAt,
            status: .taken,
            injectionSite: site
        )
        modelContext.insert(log)
        if medication.type == .injection {
            medication.advanceSite()
        }
        try? modelContext.save()
        Haptics.success()
    }

    func editLog(_ log: DoseLog, newStatus: DoseStatus, newTime: Date?) {
        guard log.isEditableNow else { return }
        log.status = newStatus
        if let newTime { log.takenTime = newTime }
        try? modelContext.save()
    }

    func auditMissedDoses(existingLogs: [DoseLog]) {
        let now = Date()
        for log in existingLogs where log.status == .pending && log.scheduledTime < now.startOfDay {
            log.status = .missed
        }
        try? modelContext.save()
    }
}
