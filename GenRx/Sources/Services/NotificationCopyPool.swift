import Foundation

enum NotificationCopyPool {
    static func genericReminder(medName: String) -> (title: String, body: String) {
        let options: [(String, String)] = [
            ("Medication reminder", "\(medName). You know the drill."),
            ("Unread: 1 medication", "From: Your Body. Subject: \(medName)."),
            ("\(medName) o'clock", "Don't make it weird."),
            ("Still ignoring \(medName)?", "Bold strategy."),
            ("\(medName)", "The \(medName) isn't going to take itself. Unfortunately."),
            ("Reminder", "Time for \(medName). Your future self is watching."),
        ]
        return options.randomElement()!
    }

    static func injectionReminder(medName: String, site: String) -> (title: String, body: String) {
        let options: [(String, String)] = [
            ("Injection time", "\(medName). \(site) is up. Get a needle."),
            ("Jab day", "\(site). Don't think about it, just do it."),
            ("\(medName) injection", "\(site). You've done harder things."),
        ]
        return options.randomElement()!
    }

    static func followUpReminder(medName: String) -> (title: String, body: String) {
        let options: [(String, String)] = [
            ("Still waiting", "Still waiting on that \(medName)."),
            ("\(medName) update", "\(medName) is giving you a look right now."),
            ("Follow-up", "One hour ago: \(medName). Still waiting."),
        ]
        return options.randomElement()!
    }

    static func morningGreeting(medName: String, scheduledTime: String) -> (title: String, body: String) {
        let options: [(String, String)] = [
            ("Rise and medicate", "Morning. Your \(medName) has been waiting since \(scheduledTime)."),
            ("Good morning", "Another day in the timeline. Let's get you chemically balanced."),
            ("Coffee can wait", "\(medName) cannot. (Coffee cannot actually wait.)"),
            ("Rise and medicate", "Your \(medName) would like a word."),
        ]
        return options.randomElement()!
    }

    static func isMorningDose(timeString: String) -> Bool {
        guard let components = timeString.split(separator: ":").compactMap({ Int($0) }) as [Int]?,
              components.count == 2 else { return false }
        return components[0] < 12
    }
}
