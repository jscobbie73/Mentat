import Foundation

enum MedicationType: String, Codable, CaseIterable {
    case pill
    case injection
    case topical
    case other

    var displayName: String {
        switch self {
        case .pill: return "Pill / Capsule"
        case .injection: return "Injection"
        case .topical: return "Topical"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .pill: return "capsule.fill"
        case .injection: return "syringe.fill"
        case .topical: return "hand.raised.fill"
        case .other: return "cross.case.fill"
        }
    }
}
