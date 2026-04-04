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

        let goal = goalForNotifications()

        for offset in 0..<14 {
            let absoluteDay = daysSinceEpoch + offset

            guard let fireDate = cal.date(byAdding: .day, value: offset, to: today) else { continue }

            scheduleDayNotification(
                at: fireDate,
                hour: morningHour,
                title: "Good morning.",
                body: morningBody(for: goal, absoluteDay: absoluteDay),
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

    /// Reads the user's stored goal so notifications can be personalised
    /// without requiring a parameter to be threaded through every call site.
    private func goalForNotifications() -> UserGoal? {
        guard let raw = UserDefaults.standard.string(forKey: "userGoal") else { return nil }
        return UserGoal(rawValue: raw)
    }

    /// Returns a morning body line, using the goal-specific pool when available
    /// and falling back to the generic pool when no goal is set.
    private func morningBody(for goal: UserGoal?, absoluteDay: Int) -> String {
        let pool: [String]
        switch goal {
        case .sleepBetter:
            pool = [
                "Another night without a glucose spike means another night your cortisol didn't fire at 3am.",
                "The sleep improvements you're working toward are building in the background. Stable blood sugar is the mechanism.",
                "Last night's sleep ran differently. Stable blood glucose removes the 3am cortisol response.",
                "Two weeks without glycemic disruption changes sleep architecture measurably. You're building toward that.",
                "Deep sleep — the restorative kind — improves when nocturnal glucose is stable. That's what you're working on.",
                "The 2–4am waking that glucose spikes cause is becoming less likely every morning.",
                "Your sleep debt is shifting. Blood sugar stability is the lever you pulled.",
                "Three stages of sleep deepen when blood sugar is stable overnight. You're building architecture, not just hours.",
                "The deep sleep window — when growth hormone peaks — isn't interrupted by glucose correction when sugar is gone.",
                "Cortisol acts as your body's alarm when blood sugar drops in the night. Eliminate the drop, eliminate the alarm.",
                "REM sleep — when memory consolidates — extends when the brain isn't managing a glucose crash.",
                "Ghrelin spikes that wake people at 3am are partly driven by the blood sugar correction cycle. Your 3am is quieter now.",
                "Adenosine — the sleep pressure molecule — accumulates cleanly when metabolic noise is low.",
                "Slow-wave sleep lengthens when nocturnal insulin is low. Last night was different from the nights before you started.",
            ]
        case .moreEnergy:
            pool = [
                "The afternoon crash you're used to is borrowed energy. What you're building now is a real baseline.",
                "Mitochondrial adaptation to fat oxidation continues today. The stable energy you may be feeling is this process.",
                "The fatigue you've normalized isn't your baseline — it's your baseline plus sugar debt. This morning is different.",
                "Real energy doesn't have a crash at the other end. You're in the process of finding out what that feels like.",
                "Your cells are adapting. The flat period most people experience is the transition, not the destination.",
                "The post-lunch crash is borrowed energy correcting itself. You're removing the borrow.",
                "What you feel this morning is closer to your actual biological baseline than what you felt a week ago.",
                "The 2pm crash you used to schedule around is no longer in the calendar.",
                "Fat oxidation is a cleaner fuel — no spike, no correction, no crash. You're building the engine that runs on it.",
                "Cortisol variability throughout the day is lower when blood sugar is stable. That's steadier energy, not just more.",
                "The flat period during transition is the system reconfiguring. On the other side is a different baseline.",
                "Energy that doesn't crash at the other end isn't a feeling — it's a different metabolic state. You're building it.",
                "Mitochondrial density in cells increases with fat as the primary substrate. More energy per molecule.",
                "The borrowed-energy cycle your body has been running is unwinding. What you feel on a clean morning is the real thing.",
            ]
        case .breakCravings:
            pool = [
                "The craving that might show up today is a reflex looking for its cue. You know how to handle it.",
                "Every day you hold, the neural pathway for the old habit weakens through disuse. Today weakens it more.",
                "The dopamine loop that drove the old pattern is losing its grip. That process is running right now.",
                "This morning's craving, if it shows up, is habit memory — not need. The distinction is everything.",
                "The compulsive edge of the craving fades by day 3. Whatever you feel now is the echo.",
                "You're interrupting a conditioned response. That's exactly what extinction training looks like.",
                "The craving cycle you started this to end is ending. Each morning is evidence.",
                "Habit extinction requires repeated exposure to the cue without the reward. That's what every day you hold is doing.",
                "The mesolimbic dopamine system is restabilizing. The compulsive quality of the old craving is losing its mechanism.",
                "Each time you're in the cue context without acting on it, the conditioned response weakens. That's the whole method.",
                "The craving pathway is still there — it just has less signal behind it now. Disuse weakens the connection.",
                "After three weeks, the conditioned craving response triggers less frequently and resolves faster. You're in that window.",
                "The old craving cue still fires — but it's quieter every time you don't answer it.",
                "What you're doing is what neuroscience calls extinction training. It works through repetition, not willpower.",
            ]
        case .loseWeight:
            pool = [
                "Fasting insulin is lower this morning than it was when you started. Every downstream system follows.",
                "Visceral fat responds faster to insulin reduction than to any other dietary change. The mechanism is running.",
                "This morning's insulin baseline is contributing to fat mobilization. That's the lever you pulled.",
                "Lower fasting insulin means less fat storage signaling overnight. That's a different morning.",
                "The fat-storage mechanism runs through insulin. Every morning clean is a morning it's lower.",
                "Two weeks of reduced insulin produces measurable changes in visceral fat. You're building toward that.",
                "Cortisol and insulin are both lower this morning. Both drive fat storage. Both are falling.",
                "Chronic insulin elevation is the primary driver of visceral fat accumulation. Yours has been falling since you started.",
                "Lipolysis — the process of breaking down stored fat for fuel — runs when insulin is low. Every morning clean is a morning it ran.",
                "The liver's ability to process fat improves as fructose-driven lipogenesis drops. The whole system is running cleaner.",
                "Fasting insulin is the single most predictive marker for metabolic health. Yours is trending down.",
                "Visceral fat comes first — it's the most metabolically dangerous kind and responds fastest to insulin reduction.",
                "Adipokines — signaling molecules from fat tissue — are shifting as visceral fat reduces. The hormonal environment is changing.",
                "The fat-burning pathway that insulin suppresses has been running longer each day. This is what that mechanism looks like from the inside.",
            ]
        case .curious:
            pool = [
                "Another day of data. Your body is telling you something you haven't heard before.",
                "Most people never run this experiment long enough to see what you're seeing. The data is yours.",
                "Your n=1 trial continues. What's your baseline this morning?",
                "The question 'what does my body actually feel like?' is one of the most interesting ones you can ask.",
                "Most people have never tracked what their actual baseline is. You're in a rare category.",
                "Each day adds to a dataset most people never collect. What are you noticing?",
                "The experiment is still running. The data is still coming in.",
                "Day-to-day energy variability is data. What pattern are you seeing?",
                "The body's default state without sugar is different for everyone. You're finding yours.",
                "Sleep, mood, hunger timing, focus — they each have their own answer. What's yours?",
                "Baseline data is rare. Most people modify their diet and notice nothing because they weren't paying attention before they started.",
                "The longer the trial runs, the more the data means. You're adding signal every day.",
                "What you're learning about your own biology right now is information you can't get any other way.",
                "The n=1 trial continues. The question 'what actually changed?' is worth asking specifically this morning.",
            ]
        case nil:
            return morningBodies[absoluteDay % morningBodies.count]
        }
        return pool[absoluteDay % pool.count]
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
        "The craving fires on schedule, not on need. Your logs confirm the schedule. You can be ready for it.",
        "This hour shows up most often in your logs. That makes it the one that matters most to close.",
        "Your peak craving window has a ceiling. You know where it is. Twenty minutes and it's done.",
        "The pattern is real and you mapped it. Knowing where the ambush is changes how you walk through it.",
        "Your data says this hour is where the old reflex looks for an opening. Don't give it one.",
        "The craving knows your schedule better than you do right now. Use the timer.",
        "Every time you hold this window, the next occurrence is slightly weaker. That's the mechanism.",
    ]

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let d = h / 24
        let rh = h % 24
        if d >= 7 { return "\(d) days" }
        if d >= 1 { return rh > 0 ? "\(d)d \(rh)h" : "\(d)d" }
        return "\(h)h"
    }

    // MARK: - Streak milestone notifications

    /// Fires ~2 s after a streak milestone is confirmed. Called from FastingStore
    /// when streakDays crosses 3, 7, 14, 30, or 100.
    func scheduleStreakMilestoneNotification(days: Int) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            let content = UNMutableNotificationContent()
            content.title = "\(days) clean day\(days == 1 ? "" : "s")."
            content.body  = self.streakMilestoneBody(for: days)
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
            let request  = UNNotificationRequest(
                identifier: "nightcap.streak.\(days)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    private func streakMilestoneBody(for days: Int) -> String {
        switch days {
        case 3:
            return "Three consecutive clean days. The withdrawal window is closing. The biology is moving."
        case 7:
            return "Seven clean days. Your gut microbiome has measurably shifted. The bacteria that amplify cravings are being starved out."
        case 14:
            return "Two weeks. fMRI studies show reduced reward-center activation at this mark. Taste, sleep, dopamine — all changed."
        case 30:
            return "Thirty clean days. Dopamine receptor density has had meaningful recovery time. This is identity now, not discipline."
        case 100:
            return "100 consecutive clean days. The neural pathway for the old habit has weakened through disuse. This is who you are."
        default:
            return "Another day further. The compound interest is accumulating."
        }
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
