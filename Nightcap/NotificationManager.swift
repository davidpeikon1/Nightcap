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

    /// Schedule 14 morning + 14 evening notifications — one per day for the next
    /// 14 days. Messages are drawn from 21-entry pools using an absolute day index
    /// so every message cycles before repeating (~3 weeks). Re-call on each app
    /// foreground to keep the window fresh. Safe to call redundantly; old requests
    /// are removed and replaced each time.
    func scheduleDailyNotifications() {
        // Remove legacy identifiers (repeating weekday-based and any prior day-based).
        var toRemove = ["nightcap.morning", "nightcap.evening"]
        for weekday in 1...7 {
            toRemove.append("nightcap.morning.wd\(weekday)")
            toRemove.append("nightcap.evening.wd\(weekday)")
        }
        for day in 0..<14 {
            toRemove.append("nightcap.morning.d\(day)")
            toRemove.append("nightcap.evening.d\(day)")
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: toRemove)

        // Determine the absolute day index since an arbitrary epoch so the pool
        // cycles globally rather than resetting on each reschedule.
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let epoch = cal.startOfDay(for: Date(timeIntervalSince1970: 0))
        let daysSinceEpoch = cal.dateComponents([.day], from: epoch, to: today).day ?? 0

        for offset in 0..<14 {
            let absoluteDay = daysSinceEpoch + offset
            let bodyIndex = absoluteDay % morningBodies.count

            guard let fireDate = cal.date(byAdding: .day, value: offset, to: today) else { continue }

            scheduleDayNotification(
                at: fireDate,
                hour: morningHour,
                title: "Good morning.",
                body: morningBodies[bodyIndex],
                identifier: "nightcap.morning.d\(offset)"
            )
            scheduleDayNotification(
                at: fireDate,
                hour: eveningHour,
                title: "Evening check-in.",
                body: eveningBodies[absoluteDay % eveningBodies.count],
                identifier: "nightcap.evening.d\(offset)"
            )
        }
    }

    private func scheduleDayNotification(at date: Date, hour: Int, title: String, body: String, identifier: String) {
        let cal = Calendar.current
        guard let fireDate = cal.date(bySettingHour: hour, minute: 0, second: 0, of: date) else { return }
        let interval = fireDate.timeIntervalSinceNow
        guard interval > 5 else { return } // already past

        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Notification body pools

    /// Fourteen morning messages — distributed across weekdays so the message
    /// rotates through both pools before repeating. Forward-looking: begins the
    /// day with curiosity and grounded context.
    private let morningBodies: [String] = [
        "This morning's reframe is ready when you are.",
        "Every day without processed sugar, your brain gets a little more of itself back.",
        "The clock is still running. That's the only thing that matters this morning.",
        "Most people won't make it this far. You have.",
        "The way you handle this morning is a vote for who you're becoming.",
        "Your baseline this morning is cleaner than it was a week ago.",
        "Progress that compounds quietly is still progress.",
        "Overnight, your body didn't spike insulin once. That's a different kind of rest.",
        "The craving you might feel today is habit memory, not hunger. The distinction matters.",
        "Every morning without a reset is compounding in ways that aren't yet visible.",
        "The biochemistry that drove yesterday's cravings is quieter this morning.",
        "Whatever happened yesterday, the clock is running and the work continues.",
        "The biology of this is working for you, even while you sleep.",
        "Another morning on the right side of this. That's the whole job.",
        "Fasting insulin is lower this morning than it was before you started. Every system downstream follows it.",
        "The conditioned craving that shows up at a specific time today is a reflex, not a need. The difference matters.",
        "One more day further than most people ever get. That's not nothing.",
        "The gut bacteria that were amplifying your cravings have been declining since you started. This morning they're weaker.",
        "Sleep last night ran on stable blood glucose. That's a different kind of recovery.",
        "Your taste receptors this morning are more sensitive than they were when you started.",
        "The work is quieter now. That's what progress looks like after the hard part is over.",
        "You committed to this when you set the clock. This morning is that commitment holding.",
        "Most people who make it this far don't remember deciding every morning. It stopped being a decision — it became who they are.",
        // Curiosity gap — hints at biological change without revealing the detail
        "What changed in your body overnight is worth knowing.",
        "Your blood chemistry shifted while you slept. Open to find out how.",
    ]

    /// Fourteen evening messages — distributed across weekdays so the message
    /// rotates through both pools before repeating. Present-tense shielding:
    /// acknowledges the moment without alarm.
    private let eveningBodies: [String] = [
        "The hour after dinner is where most streaks end. Not tonight.",
        "The evening pull is mostly habit. It will pass without you.",
        "The craving window is 20 minutes. You've outlasted it before.",
        "The best thing you can do for tomorrow morning is to close tonight right.",
        "Evenings are where most people reset. Not you.",
        "This is the hardest part of the day. You know what to do.",
        "One more evening. That's all you have to do right now.",
        "A late craving isn't hunger — it's a habit looking for its cue. Give it nothing.",
        "Evening is when the old pattern looks for an opening. You've closed it before.",
        "Sleep locks in what today built. Don't undo it in the last hour.",
        "The pull you feel right now has a 20-minute ceiling. You know this.",
        "End tonight the same way you started this morning.",
        "Still running. That's the whole job tonight.",
        "Every evening you hold the line, tomorrow gets easier.",
        "Tonight's cortisol won't spike at 3am looking for glucose to stabilize. That's a different sleep.",
        "The evening craving is the pattern looking for its window. Close it.",
        "What you don't eat tonight is compounding toward tomorrow's baseline.",
        "The reflex will look for you around now. You've seen it before. You know how it ends.",
        "Hold the evening and the morning takes care of itself.",
        "The hard part of today is the next 90 minutes. After that, the biology quiets down.",
        "Every night you close clean, the biology of tomorrow starts stronger.",
        "More resets happen in the next 90 minutes than any other time of day. You're in the window. Hold it.",
        "The people who change this are the ones who close tonight. You're one of them.",
        // Curiosity gap — hints at biological stakes without spelling them out
        "What's at stake in the next two hours is specific and biological.",
        "The biology of tomorrow is being written right now.",
    ]

    // MARK: - Personal Best notifications

    /// Schedules two notifications around the user's personal best threshold:
    ///   1. An approach alert 2 hours before the PB — fires even when app is closed.
    ///   2. An achievement alert at the exact moment the PB is broken.
    /// Safe to call redundantly; previous PB notifications are removed first.
    func schedulePersonalBestNotifications(from lastSugarDate: Date, previousBest: TimeInterval) {
        let ids = ["nightcap.pb.approach", "nightcap.pb.achieved"]
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        guard previousBest > 3_600 else { return } // skip trivially short PBs

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            let pbDate       = lastSugarDate.addingTimeInterval(previousBest)
            let approachDate = pbDate.addingTimeInterval(-7_200)
            let now          = Date()

            // Approach notification — 2 hours before PB
            let approachInterval = approachDate.timeIntervalSince(now)
            if approachInterval > 5 {
                let content  = UNMutableNotificationContent()
                content.title = "2 hours from your personal best."
                content.body  = "You've never made it past \(self.formattedDuration(previousBest)) before. You're about to."
                content.sound = .default
                let trigger  = UNTimeIntervalNotificationTrigger(timeInterval: approachInterval, repeats: false)
                let request  = UNNotificationRequest(identifier: "nightcap.pb.approach", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }

            // Achievement notification — at the exact PB moment
            let achieveInterval = pbDate.timeIntervalSince(now)
            if achieveInterval > 5 {
                let content  = UNMutableNotificationContent()
                content.title = "Personal best."
                content.body  = "You just went further than \(self.formattedDuration(previousBest)). New record."
                content.sound = .default
                let trigger  = UNTimeIntervalNotificationTrigger(timeInterval: achieveInterval, repeats: false)
                let request  = UNNotificationRequest(identifier: "nightcap.pb.achieved", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }

    func clearPersonalBestNotifications() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["nightcap.pb.approach", "nightcap.pb.achieved"]
        )
    }

    // MARK: - Personalized peak-craving notification

    /// Schedules a daily notification at the user's statistically peak craving hour.
    /// Only fires if the peak is in the afternoon/evening window (2pm–11pm) and is
    /// at least 2 hours away from the existing morning and evening slots to avoid spam.
    /// Called when craving data reaches a meaningful threshold (5+ logs).
    func schedulePersonalizedNotification(peakHour: Int) {
        guard (14...23).contains(peakHour) else { return }
        // Don't double-up within 2 hours of the existing scheduled slots.
        guard abs(peakHour - morningHour) > 2, abs(peakHour - eveningHour) > 2 else { return }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }

            // Remove stale personalized notifications.
            let toRemove = (0..<14).map { "nightcap.personalized.d\($0)" }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: toRemove)

            let cal = Calendar.current
            let today = cal.startOfDay(for: Date())
            let epoch = cal.startOfDay(for: Date(timeIntervalSince1970: 0))
            let daysSinceEpoch = cal.dateComponents([.day], from: epoch, to: today).day ?? 0

            for offset in 0..<14 {
                let absoluteDay = daysSinceEpoch + offset
                guard let fireDate = cal.date(byAdding: .day, value: offset, to: today) else { continue }
                self.scheduleDayNotification(
                    at: fireDate,
                    hour: peakHour,
                    title: "This is your window.",
                    body: self.personalizedBodies[absoluteDay % self.personalizedBodies.count],
                    identifier: "nightcap.personalized.d\(offset)"
                )
            }
        }
    }

    private let personalizedBodies: [String] = [
        "Your data shows this is when the craving usually shows up. You know the pattern. You know what to do.",
        "This is the window where your streak is most at risk. Hold it.",
        "The pull is predictable. Which means the defense can be too.",
        "Your craving history peaks around now. The 20-minute timer exists for exactly this moment.",
        "Pattern recognized. What happens in the next 20 minutes is the whole game.",
        "The data says this is your window. The craving is a schedule. You can work with a schedule.",
        "Your logs put this as the high-risk hour. You already know how to get through it.",
    ]

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let d = h / 24
        let rh = h % 24
        if d >= 7 { return "\(d) days" }
        if d >= 1 { return rh > 0 ? "\(d)d \(rh)h" : "\(d)d" }
        return "\(h)h"
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
