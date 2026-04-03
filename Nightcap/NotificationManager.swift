import Foundation
import UserNotifications

class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    // MARK: - Permission

    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            DispatchQueue.main.async {
                if granted { self.scheduleDailyNotifications() }
                completion(granted)
            }
        }
    }

    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(settings.authorizationStatus) }
        }
    }

    // MARK: - Scheduling

    func scheduleDailyNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        scheduleEvening()
        scheduleMorning()
    }

    private func scheduleEvening() {
        let content = UNMutableNotificationContent()
        content.title = "Evening check-in."
        content.body  = "This is the highest-risk hour for sugar. Your toolkit is one tap away."
        content.sound = .default

        var components = DateComponents()
        components.hour   = 21
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "nightcap.evening",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleMorning() {
        let content = UNMutableNotificationContent()
        content.title = "Good morning."
        content.body  = "Your fast is still running. A new reframe is waiting."
        content.sound = .default

        var components = DateComponents()
        components.hour   = 7
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "nightcap.morning",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Milestone notifications

    func scheduleMilestoneNotification(badge: BadgeID) {
        let content = UNMutableNotificationContent()
        content.title = "\(badge.label)."
        content.body  = badge.scienceFact
        content.sound = .default

        // Fire immediately (after 1 second) as a local push
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "nightcap.milestone.\(badge.rawValue)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
