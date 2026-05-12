import Foundation

enum DoseStatus: String, Codable {
    case pending
    case taken
    case skipped
    case missed

    var displayLabel: String {
        rawValue
    }

    var isActionable: Bool {
        self == .pending
    }
}
