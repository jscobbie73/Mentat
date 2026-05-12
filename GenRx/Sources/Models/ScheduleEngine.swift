import Foundation

enum ScheduleEngine {
    static func dosesForToday(medications: [Medication], existingLogs: [DoseLog]) -> [ScheduledDose] {
        let today = Date()
        var doses: [ScheduledDose] = []

        for med in medications where med.isActive && med.frequency != .asNeeded {
            guard shouldFireToday(medication: med, referenceDate: today) else { continue }
            for timeString in med.timesOfDay {
                guard let scheduledTime = Date.fromTimeString(timeString) else { continue }
                let existingLog = existingLogs.first {
                    $0.medicationID == med.id && abs($0.scheduledTime.timeIntervalSince(scheduledTime)) < 60
                }
                let status = existingLog?.status ?? (scheduledTime < today ? .missed : .pending)
                doses.append(ScheduledDose(
                    id: existingLog?.id ?? UUID(),
                    medication: med,
                    scheduledTime: scheduledTime,
                    status: status,
                    existingLog: existingLog
                ))
            }
        }

        return doses.sorted { $0.scheduledTime < $1.scheduledTime }
    }

    static func shouldFireToday(medication: Medication, referenceDate: Date) -> Bool {
        switch medication.frequency {
        case .daily:
            return true
        case .weekly:
            let weekday = Calendar.current.component(.weekday, from: referenceDate)
            return medication.daysOfWeek.contains(weekday)
        case .everyNDays:
            let daysSinceStart = Calendar.current.dateComponents([.day], from: medication.startDate.startOfDay, to: referenceDate.startOfDay).day ?? 0
            guard daysSinceStart >= 0 else { return false }
            return daysSinceStart % medication.intervalDays == 0
        case .asNeeded:
            return false
        }
    }

    static func nextOccurrences(for medication: Medication, count: Int, after date: Date) -> [Date] {
        var results: [Date] = []
        var candidate = date

        while results.count < count {
            candidate = Calendar.current.date(byAdding: .day, value: 1, to: candidate) ?? candidate
            if shouldFireToday(medication: medication, referenceDate: candidate) {
                for timeString in medication.timesOfDay {
                    guard let fireDate = Date.fromTimeString(timeString, on: candidate) else { continue }
                    if fireDate > date {
                        results.append(fireDate)
                        if results.count >= count { break }
                    }
                }
            }
            // Safety: bail after 2 years of searching
            if candidate > date.addingTimeInterval(60 * 60 * 24 * 730) { break }
        }

        return results
    }
}
