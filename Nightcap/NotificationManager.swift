import Foundation
import UserNotifications

extension Int {
    /// Converts an hour integer (0–23) to a Date for use with DatePicker.
    var asTime: Date {
        Calendar.current.date(
            bySettingHour: self, minute: 0, second: 0, of: Date()
        ) ?? Date()
    }
}

class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    // MARK: - Persisted time preferences

    private let defaults = UserDefaults.standard

    var morningHour: Int {
        get { defaults.object(forKey: "notif.morningHour") != nil ? defaults.integer(forKey: "notif.morningHour") : 7 }
        set { defaults.set(newValue, forKey: "notif.morningHour") }
    }

    var eveningHour: Int {
        get { defaults.object(forKey: "notif.eveningHour") != nil ? defaults.integer(forKey: "notif.eveningHour") : 21 }
        set { defaults.set(newValue, forKey: "notif.eveningHour") }
    }

    func updateMorningHour(_ hour: Int) {
        morningHour = hour
        scheduleDailyNotifications()
    }

    func updateEveningHour(_ hour: Int) {
        eveningHour = hour
        scheduleDailyNotifications()
    }

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

    /// Schedule 7 morning + 7 evening notifications — one for each day of the week —
    /// so the message body varies daily. Re-call on each app foreground to keep the
    /// upcoming week fresh. Safe to call redundantly; old requests are replaced.
    func scheduleDailyNotifications() {
        // Remove legacy single-repeating identifiers and all day-specific ones.
        var toRemove = ["nightcap.morning", "nightcap.evening"]
        for weekday in 1...7 {
            toRemove.append("nightcap.morning.wd\(weekday)")
            toRemove.append("nightcap.evening.wd\(weekday)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: toRemove)

        for weekday in 1...7 {
            scheduleWeekdayNotification(
                weekday: weekday,
                hour: morningHour,
                title: "Good morning.",
                bodies: morningBodies,
                identifier: "nightcap.morning.wd\(weekday)"
            )
            scheduleWeekdayNotification(
                weekday: weekday,
                hour: eveningHour,
                title: "Evening check-in.",
                bodies: eveningBodies,
                identifier: "nightcap.evening.wd\(weekday)"
            )
        }
    }

    private func scheduleWeekdayNotification(
        weekday: Int, hour: Int, title: String, bodies: [String], identifier: String
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = bodies[(weekday - 1) % bodies.count]
        content.sound = .default

        var components = DateComponents()
        components.weekday = weekday
        components.hour    = hour
        components.minute  = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Notification body pools

    /// Seven morning messages — one fires per day-of-week (Sunday–Saturday).
    /// Forward-looking: begins the day with curiosity and context.
    private let morningBodies: [String] = [
        "A new reframe is ready for today.",
        "Every day without processed sugar, your brain gets a little more of itself back.",
        "The clock is still running. That's the only thing that matters this morning.",
        "Most people won't make it this far. You have.",
        "The way you handle this morning is a vote for who you're becoming.",
        "Your baseline this morning is cleaner than it was a week ago.",
        "Progress that compounds quietly is still progress.",
    ]

    /// Seven evening messages — one fires per day-of-week (Sunday–Saturday).
    /// Present-tense shielding: acknowledges the moment without alarm.
    private let eveningBodies: [String] = [
        "This is the highest-risk hour for sugar.",
        "The evening pull is mostly habit. It will pass without you.",
        "The craving window is 20 minutes. You've outlasted it before.",
        "Check in with yourself. You've made it to another evening.",
        "Evenings are where most people reset. Not you.",
        "This is the hardest part of the day. You know what to do.",
        "One more evening. That's all you have to do right now.",
    ]

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

            // Remove any previously scheduled future milestone and approach notifications.
            let identifiers = BadgeID.allCases.flatMap { [
                "nightcap.milestone.future.\($0.rawValue)",
                "nightcap.milestone.approach.\($0.rawValue)"
            ] }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)

            let now = Date()
            for badge in BadgeID.allCases {
                guard !earnedBadges.contains(badge) else { continue }
                let unlockDate = lastSugarDate.addingTimeInterval(badge.threshold)
                let interval   = unlockDate.timeIntervalSince(now)
                guard interval > 5 else { continue } // already passed (or imminent)

                // ── Milestone notification (fires at the moment of unlock) ──
                let content = UNMutableNotificationContent()
                content.title = "\(badge.label)."
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

                // ── Approach notification (fires in the final stretch) ──
                if let approachWindow = badge.approachInterval,
                   !badge.approachBody.isEmpty {
                    let approachInterval = interval - approachWindow
                    guard approachInterval > 5 else { continue }

                    let approachContent = UNMutableNotificationContent()
                    approachContent.title = "Almost there."
                    approachContent.body  = badge.approachBody
                    approachContent.sound = .default

                    let approachTrigger = UNTimeIntervalNotificationTrigger(
                        timeInterval: approachInterval, repeats: false
                    )
                    let approachRequest = UNNotificationRequest(
                        identifier: "nightcap.milestone.approach.\(badge.rawValue)",
                        content: approachContent,
                        trigger: approachTrigger
                    )
                    UNUserNotificationCenter.current().add(approachRequest)
                }
            }
        }
    }
}
