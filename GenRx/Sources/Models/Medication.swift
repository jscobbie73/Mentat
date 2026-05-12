import Foundation
import SwiftData

@Model
final class Medication {
    var id: UUID
    var name: String
    var type: MedicationType
    var dosage: String
    var frequency: FrequencyType
    var timesOfDay: [String]        // ["08:00", "20:00"] 24hr strings
    var daysOfWeek: [Int]           // 1=Sunday … 7=Saturday
    var intervalDays: Int           // for everyNDays
    var startDate: Date
    var injectionSites: [String]
    var currentSiteIndex: Int
    var colorHex: String
    var notes: String
    var isActive: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        type: MedicationType = .pill,
        dosage: String = "",
        frequency: FrequencyType = .daily,
        timesOfDay: [String] = ["08:00"],
        daysOfWeek: [Int] = [],
        intervalDays: Int = 7,
        startDate: Date = Date(),
        injectionSites: [String] = [],
        currentSiteIndex: Int = 0,
        colorHex: String = "#FF2D78",
        notes: String = "",
        isActive: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.dosage = dosage
        self.frequency = frequency
        self.timesOfDay = timesOfDay
        self.daysOfWeek = daysOfWeek
        self.intervalDays = intervalDays
        self.startDate = startDate
        self.injectionSites = injectionSites
        self.currentSiteIndex = currentSiteIndex
        self.colorHex = colorHex
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
    }

    var currentInjectionSite: String? {
        guard type == .injection, !injectionSites.isEmpty else { return nil }
        return injectionSites[safe: currentSiteIndex]
    }

    var nextInjectionSite: String? {
        guard type == .injection, injectionSites.count > 1 else { return nil }
        let nextIndex = (currentSiteIndex + 1) % injectionSites.count
        return injectionSites[safe: nextIndex]
    }

    func advanceSite() {
        guard type == .injection, !injectionSites.isEmpty else { return }
        currentSiteIndex = (currentSiteIndex + 1) % injectionSites.count
    }

    var scheduleSummary: String {
        switch frequency {
        case .daily:
            let times = timesOfDay.compactMap { Date.fromTimeString($0) }.map { $0.formatted(date: .omitted, time: .shortened) }
            return "Daily · \(times.joined(separator: ", "))"
        case .weekly:
            let dayNames = daysOfWeek.sorted().compactMap { Calendar.current.shortWeekdaySymbols[safe: $0 - 1] }
            return "Weekly · \(dayNames.joined(separator: ", "))"
        case .everyNDays:
            return "Every \(intervalDays) days"
        case .asNeeded:
            return "As needed"
        }
    }
}
