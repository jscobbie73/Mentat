import Foundation
import UserNotifications
import SwiftData
import Observation

private let notificationBudget = 60
private let everyNDaysOccurrenceCount = 8

@Observable
final class NotificationScheduler: NSObject, UNUserNotificationCenterDelegate {
    var isAuthorized = false
    private var followUpDelayMinutes: Int = 30

    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        registerNotificationCategories()
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Schedule All

    func scheduleAll(medications: [Medication]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        var budget = notificationBudget
        for med in medications where med.isActive && med.frequency != .asNeeded {
            let slots = estimatedSlots(for: med)
            guard budget - slots >= 0 else { continue }
            scheduleMedication(med)
            budget -= slots
        }
    }

    func cancelNotifications(for medication: Medication) {
        let prefix = notificationPrefix(for: medication)
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.filter { $0.identifier.hasPrefix(prefix) }.map(\.identifier)
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
    }

    // MARK: - Reschedule on foreground

    func auditAndReschedule(modelContainer: ModelContainer) async {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Medication>(predicate: #Predicate { $0.isActive })
        guard let medications = try? context.fetch(descriptor) else { return }

        let pending = await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                continuation.resume(returning: requests)
            }
        }

        for med in medications where med.frequency == .everyNDays {
            let prefix = notificationPrefix(for: med)
            let existing = pending.filter { $0.identifier.hasPrefix(prefix) }.count
            if existing < 4 {
                scheduleEveryNDays(med)
            }
        }
    }

    // MARK: - Private scheduling

    private func scheduleMedication(_ medication: Medication) {
        switch medication.frequency {
        case .daily: scheduleDaily(medication)
        case .weekly: scheduleWeekly(medication)
        case .everyNDays: scheduleEveryNDays(medication)
        case .asNeeded: break
        }
    }

    private func scheduleDaily(_ med: Medication) {
        for timeString in med.timesOfDay {
            let copy = copyFor(med, timeString: timeString)
            let content = makeContent(title: copy.title, body: copy.body, userInfo: userInfo(for: med))
            guard let components = timeComponents(from: timeString) else { continue }
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let id = "\(notificationPrefix(for: med))daily-\(timeString)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    private func scheduleWeekly(_ med: Medication) {
        for day in med.daysOfWeek {
            for timeString in med.timesOfDay {
                let copy = copyFor(med, timeString: timeString)
                let content = makeContent(title: copy.title, body: copy.body, userInfo: userInfo(for: med))
                guard var components = timeComponents(from: timeString) else { continue }
                components.weekday = day
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let id = "\(notificationPrefix(for: med))weekly-\(day)-\(timeString)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    private func scheduleEveryNDays(_ med: Medication) {
        let occurrences = ScheduleEngine.nextOccurrences(for: med, count: everyNDaysOccurrenceCount, after: Date())
        for (index, date) in occurrences.enumerated() {
            let copy = copyFor(med, timeString: nil)
            let content = makeContent(title: copy.title, body: copy.body, userInfo: userInfo(for: med))
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let id = "\(notificationPrefix(for: med))interval-\(index)-\(Int(date.timeIntervalSince1970))"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request)
        }
    }

    // MARK: - Delegate (action handling)

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        switch response.actionIdentifier {
        case "SNOOZE":
            snooze(response: response, userInfo: userInfo)
        default:
            break
        }
        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    private func snooze(response: UNNotificationResponse, userInfo: [AnyHashable: Any]) {
        let original = response.notification.request.content.mutableCopy() as! UNMutableNotificationContent
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 15 * 60, repeats: false)
        let id = response.notification.request.identifier + "-snooze"
        let request = UNNotificationRequest(identifier: id, content: original, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Helpers

    private func registerNotificationCategories() {
        let takeAction = UNNotificationAction(identifier: "MARK_TAKEN", title: "Take it", options: [.foreground])
        let snoozeAction = UNNotificationAction(identifier: "SNOOZE", title: "Not yet", options: [])
        let category = UNNotificationCategory(identifier: "DOSE_REMINDER", actions: [takeAction, snoozeAction], intentIdentifiers: [])
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    private func makeContent(title: String, body: String, userInfo: [AnyHashable: Any]) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = "DOSE_REMINDER"
        content.userInfo = userInfo
        return content
    }

    private func notificationPrefix(for med: Medication) -> String {
        "genrx-\(med.id)-"
    }

    private func userInfo(for med: Medication) -> [String: String] {
        ["medicationID": med.id.uuidString, "medicationName": med.name]
    }

    private func timeComponents(from timeString: String) -> DateComponents? {
        let parts = timeString.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else { return nil }
        return DateComponents(hour: parts[0], minute: parts[1])
    }

    private func copyFor(_ med: Medication, timeString: String?) -> (title: String, body: String) {
        if med.type == .injection, let site = med.currentInjectionSite {
            return NotificationCopyPool.injectionReminder(medName: med.name, site: site)
        }
        if let ts = timeString, NotificationCopyPool.isMorningDose(timeString: ts),
           let fireDate = Date.fromTimeString(ts) {
            return NotificationCopyPool.morningGreeting(medName: med.name, scheduledTime: fireDate.timeString())
        }
        return NotificationCopyPool.genericReminder(medName: med.name)
    }

    private func estimatedSlots(for med: Medication) -> Int {
        switch med.frequency {
        case .daily: return med.timesOfDay.count
        case .weekly: return med.daysOfWeek.count * med.timesOfDay.count
        case .everyNDays: return everyNDaysOccurrenceCount
        case .asNeeded: return 0
        }
    }
}
