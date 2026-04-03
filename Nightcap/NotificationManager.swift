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

    /// Fires immediately (1 s) when the user is in-app and earns a badge.
    func scheduleMilestoneNotification(badge: BadgeID) {
        let content = UNMutableNotificationContent()
        content.title = "\(badge.label)."
        content.body  = badge.scienceFact
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "nightcap.milestone.\(badge.rawValue)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Schedules a future notification for every unearned milestone based on
    /// when it will be reached. Called whenever lastSugarDate changes so users
    /// receive a notification even if they never open the app again.
    func scheduleFutureMilestoneNotifications(from lastSugarDate: Date, earnedBadges: Set<BadgeID>) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            // Remove any previously scheduled future milestone notifications.
            let identifiers = BadgeID.allCases.map { "nightcap.milestone.future.\($0.rawValue)" }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)

            let now = Date()
            for badge in BadgeID.allCases {
                guard !earnedBadges.contains(badge) else { continue }
                let unlockDate = lastSugarDate.addingTimeInterval(badge.threshold)
                let interval   = unlockDate.timeIntervalSince(now)
                guard interval > 5 else { continue } // already passed (or imminent)

                let content = UNMutableNotificationContent()
                content.title = "\(badge.label)."
                // Keep body concise for lock screen; use first sentence of celebration text.
                let body = badge.celebrationText
                    .components(separatedBy: "\n")
                    .first?
                    .trimmingCharacters(in: .whitespaces) ?? badge.celebrationText
                content.body  = body
                content.sound = .default

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
                let request  = UNNotificationRequest(
                    identifier: "nightcap.milestone.future.\(badge.rawValue)",
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
}
