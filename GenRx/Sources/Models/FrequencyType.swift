import Foundation

enum FrequencyType: String, Codable, CaseIterable {
    case daily
    case weekly
    case everyNDays
    case asNeeded

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .everyNDays: return "Every N Days"
        case .asNeeded: return "As Needed (PRN)"
        }
    }

    var shortSummary: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .everyNDays: return "Interval"
        case .asNeeded: return "PRN"
        }
    }
}
