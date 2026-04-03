import Foundation
import Combine
import UIKit

// MARK: - Supporting Types

enum BadgeID: String, CaseIterable, Codable, Identifiable {
    var id: String { rawValue }
    case firstHour    = "first_hour"
    case firstDay     = "first_day"
    case threeDays    = "three_days"
    case oneWeek      = "one_week"
    case twoWeeks     = "two_weeks"
    case oneMonth     = "one_month"
    case hundredDays  = "hundred_days"

    var threshold: TimeInterval {
        switch self {
        case .firstHour:   return 3_600
        case .firstDay:    return 86_400
        case .threeDays:   return 86_400 * 3
        case .oneWeek:     return 86_400 * 7
        case .twoWeeks:    return 86_400 * 14
        case .oneMonth:    return 86_400 * 30
        case .hundredDays: return 86_400 * 100
        }
    }

    var label: String {
        switch self {
        case .firstHour:   return "First Hour"
        case .firstDay:    return "First Day"
        case .threeDays:   return "3 Days"
        case .oneWeek:     return "1 Week"
        case .twoWeeks:    return "2 Weeks"
        case .oneMonth:    return "1 Month"
        case .hundredDays: return "100 Days"
        }
    }

    var symbol: String {
        switch self {
        case .firstHour:   return "timer"
        case .firstDay:    return "sun.horizon"
        case .threeDays:   return "3.circle"
        case .oneWeek:     return "7.circle"
        case .twoWeeks:    return "calendar"
        case .oneMonth:    return "moon.stars"
        case .hundredDays: return "seal"
        }
    }

    var scienceFact: String {
        switch self {
        case .firstHour:
            return "Your blood sugar has started to stabilize. The craving peak — a 20-minute neurochemical event — has passed."
        case .firstDay:
            return "Your liver has cleared most of the fructose from your last meal. Insulin is falling toward baseline. Sleep tonight will be different."
        case .threeDays:
            return "Dopamine receptor sensitivity is beginning to recover. Taste receptor reset has started — natural flavors are about to get more interesting."
        case .oneWeek:
            return "Your gut microbiome has measurably shifted. Firmicutes (the craving-amplifying bacteria) are decreasing. Bacteroidetes are growing."
        case .twoWeeks:
            return "fMRI studies show reduced reward-center activation in response to sugar images at two weeks. You have literally rewired."
        case .oneMonth:
            return "D2 receptor density — suppressed by chronic dopamine spikes — has had meaningful time to recover. The baseline you feel now is closer to your actual biology."
        case .hundredDays:
            return "100 days. The neural pathway for the old habit has weakened through disuse. The new pattern has strengthened through repetition. This is identity now."
        }
    }

    var celebrationText: String {
        switch self {
        case .firstHour:   return "The first hour is the hardest commitment."
        case .firstDay:    return "One full day."
        case .threeDays:   return "Three days. The compulsive edge is fading."
        case .oneWeek:
            return "Your gut has changed.\nYour sleep has changed.\nThis is real."
        case .twoWeeks:    return "Two weeks. You've crossed the threshold most people never reach."
        case .oneMonth:    return "A month. Something real has changed — inside and out."
        case .hundredDays: return "100 days.\nYou're not trying to quit sugar anymore.\nYou don't eat it."
        }
    }

    var useConfetti: Bool {
        switch self {
        case .oneMonth, .hundredDays: return true
        default: return false
        }
    }
}

enum CravingTrigger: String, CaseIterable, Codable, Identifiable {
    case boredom  = "Boredom"
    case stress   = "Stress"
    case habit    = "Habit / time of day"
    case social   = "Social situation"

    var id: String { rawValue }

    var insight: String {
        switch self {
        case .boredom: return "Boredom cravings are the brain seeking dopamine through the easiest available route. A 5-minute walk produces the same effect."
        case .stress:  return "Stress triggers cortisol, which drives glucose cravings as a quick energy fix. Deep breathing lowers cortisol within 2 minutes."
        case .habit:   return "Habit cravings are conditioned responses — the brain fires the craving because it expects the reward at this time, in this place."
        case .social:  return "Social eating cues are among the strongest — the brain associates group contexts with shared food rewards. Having a non-sugar alternative helps."
        }
    }
}

struct CravingLog: Codable, Identifiable {
    let id: UUID
    let date: Date
    let trigger: CravingTrigger
    let resolved: Bool

    init(trigger: CravingTrigger, resolved: Bool = true) {
        self.id = UUID()
        self.date = Date()
        self.trigger = trigger
        self.resolved = resolved
    }
}

struct ResetEvent: Codable, Identifiable {
    let id: UUID
    let date: Date
    let fastDuration: TimeInterval
    let note: String?

    init(date: Date = Date(), fastDuration: TimeInterval, note: String?) {
        self.id = UUID()
        self.date = date
        self.fastDuration = fastDuration
        self.note = note
    }
}

// MARK: - Timer Display

enum TimerDisplay {
    case minutesSeconds(Int, Int)
    case hoursMinutes(Int, Int)
    case daysHoursMinutes(Int, Int, Int)
    case days(Int)
}

// MARK: - Fasting Phase

enum FastingPhase: String, CaseIterable, Hashable {
    case justStarted  = "Starting Out"
    case firstDay     = "First Day"
    case withdrawal   = "Withdrawal"
    case breakthrough = "Breakthrough"
    case rewiring     = "Rewiring"
    case freedom      = "Freedom"

    var tagline: String {
        switch self {
        case .justStarted:  return "The fast has begun."
        case .firstDay:     return "Cravings peak and pass."
        case .withdrawal:   return "Your body is adapting."
        case .breakthrough: return "The compulsion is fading."
        case .rewiring:     return "Rewriting the blueprint."
        case .freedom:      return "You're free."
        }
    }

    var bodyScience: String {
        switch self {
        case .justStarted:
            return "Your blood sugar is beginning to stabilize. The craving you feel is your brain expecting its usual dopamine hit — not your body needing fuel."
        case .firstDay:
            return "Your liver is burning through glycogen reserves. Any fatigue you feel is the metabolic shift starting. It ends by tonight."
        case .withdrawal:
            return "Headaches and irritability now are your brain recalibrating reward pathways. Serotonin production is shifting back to your gut — which is in flux but healing."
        case .breakthrough:
            return "The compulsive edge of cravings drops sharply at 72 hours. Your taste receptors are beginning to reset — an apple will soon taste like dessert."
        case .rewiring:
            return "Your gut microbiome has measurably shifted. Bacteria that amplify cravings are dying off. Bacteria that produce calm and clarity are growing."
        case .freedom:
            return "At two weeks, fMRI studies show reduced reward-center activation in response to sugar images. You have literally rewired."
        }
    }

    var previousThreshold: Double {
        switch self {
        case .justStarted:  return 0
        case .firstDay:     return 3_600
        case .withdrawal:   return 86_400
        case .breakthrough: return 259_200
        case .rewiring:     return 604_800
        case .freedom:      return 1_209_600
        }
    }

    var nextThreshold: Double {
        switch self {
        case .justStarted:  return 3_600
        case .firstDay:     return 86_400
        case .withdrawal:   return 259_200
        case .breakthrough: return 604_800
        case .rewiring:     return 1_209_600
        case .freedom:      return 1_209_600
        }
    }

    var milestoneLabel: String {
        switch self {
        case .justStarted:  return "< 1 hour"
        case .firstDay:     return "1 hour"
        case .withdrawal:   return "24 hours"
        case .breakthrough: return "72 hours"
        case .rewiring:     return "1 week"
        case .freedom:      return "2 weeks"
        }
    }
}

// MARK: - FastingStore

class FastingStore: ObservableObject {

    // MARK: Published

    @Published var lastSugarDate: Date? {
        didSet {
            defaults.set(lastSugarDate, forKey: Keys.lastSugarDate)
            updateElapsed()
        }
    }
    @Published var elapsedSeconds: TimeInterval = 0
    @Published var streakDays: Int = 0
    @Published var earnedBadges: Set<BadgeID> = []
    @Published var newlyUnlockedBadge: BadgeID? = nil
    @Published var cravingLogs: [CravingLog] = []
    @Published var resetEvents: [ResetEvent] = []

    // MARK: Private

    private var timer: AnyCancellable?
    private let defaults = UserDefaults.standard
    private var lastStreakCheckDate: Date = .distantPast

    private enum Keys {
        static let lastSugarDate    = "lastSugarDate"
        static let streakDays       = "streakDays"
        static let lastStreakCheck  = "lastStreakCheckDate"
        static let earnedBadges     = "earnedBadges"
        static let cravingLogs      = "cravingLogs"
        static let resetEvents      = "resetEvents"
    }

    // MARK: Init

    init() {
        self.lastSugarDate     = defaults.object(forKey: Keys.lastSugarDate) as? Date
        self.streakDays        = defaults.integer(forKey: Keys.streakDays)
        self.lastStreakCheckDate = (defaults.object(forKey: Keys.lastStreakCheck) as? Date) ?? .distantPast
        self.earnedBadges      = loadBadges()
        self.cravingLogs       = loadDecodable(forKey: Keys.cravingLogs) ?? []
        self.resetEvents       = loadDecodable(forKey: Keys.resetEvents) ?? []

        updateElapsed()
        startTimer()
    }

    // MARK: Actions

    func logSugar(at date: Date = Date(), note: String? = nil) {
        let event = ResetEvent(fastDuration: elapsedSeconds, note: note)
        resetEvents.insert(event, at: 0)
        if resetEvents.count > 200 { resetEvents = Array(resetEvents.prefix(200)) }
        saveDecodable(resetEvents, forKey: Keys.resetEvents)

        streakDays = 0
        defaults.set(0, forKey: Keys.streakDays)
        lastStreakCheckDate = .distantPast
        defaults.set(Date.distantPast, forKey: Keys.lastStreakCheck)

        lastSugarDate = date
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    func logCraving(_ trigger: CravingTrigger) {
        let log = CravingLog(trigger: trigger)
        cravingLogs.insert(log, at: 0)
        if cravingLogs.count > 500 { cravingLogs = Array(cravingLogs.prefix(500)) }
        saveDecodable(cravingLogs, forKey: Keys.cravingLogs)
    }

    func dismissBadge() {
        newlyUnlockedBadge = nil
    }

    // MARK: Private

    private func startTimer() {
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateElapsed()
                self?.updateStreak()
            }
    }

    private func updateElapsed() {
        guard let d = lastSugarDate else { elapsedSeconds = 0; return }
        elapsedSeconds = max(0, Date().timeIntervalSince(d))
        checkBadges()
    }

    private func updateStreak() {
        guard let lastSugar = lastSugarDate else { return }
        let cal   = Calendar.current
        let today = cal.startOfDay(for: Date())
        let last  = cal.startOfDay(for: lastStreakCheckDate)

        guard today != last else { return }

        let daysSinceReset = cal.dateComponents([.day], from: lastSugar, to: Date()).day ?? 0
        if daysSinceReset >= 1 && today > last {
            streakDays += 1
            defaults.set(streakDays, forKey: Keys.streakDays)
            lastStreakCheckDate = today
            defaults.set(today, forKey: Keys.lastStreakCheck)
        }
    }

    private func checkBadges() {
        for badge in BadgeID.allCases {
            guard !earnedBadges.contains(badge) else { continue }
            if elapsedSeconds >= badge.threshold {
                earnedBadges.insert(badge)
                saveBadges()
                newlyUnlockedBadge = badge
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                break // one at a time
            }
        }
    }

    // MARK: Persistence helpers

    private func loadBadges() -> Set<BadgeID> {
        guard let raw = defaults.stringArray(forKey: Keys.earnedBadges) else { return [] }
        return Set(raw.compactMap { BadgeID(rawValue: $0) })
    }

    private func saveBadges() {
        defaults.set(earnedBadges.map(\.rawValue), forKey: Keys.earnedBadges)
    }

    private func loadDecodable<T: Decodable>(forKey key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private func saveDecodable<T: Encodable>(_ value: T, forKey key: String) {
        defaults.set(try? JSONEncoder().encode(value), forKey: key)
    }

    // MARK: Computed

    var isTracking: Bool { lastSugarDate != nil }

    var fastingPhase: FastingPhase {
        let h = elapsedSeconds / 3600
        switch h {
        case ..<1:      return .justStarted
        case 1..<24:    return .firstDay
        case 24..<72:   return .withdrawal
        case 72..<168:  return .breakthrough
        case 168..<336: return .rewiring
        default:        return .freedom
        }
    }

    var phaseProgress: Double {
        let prev = fastingPhase.previousThreshold
        let next = fastingPhase.nextThreshold
        guard next > prev else { return 1.0 }
        return min(1.0, (elapsedSeconds - prev) / (next - prev))
    }

    var timerDisplay: TimerDisplay {
        let total = Int(elapsedSeconds)
        let days  = total / 86400
        let hours = (total % 86400) / 3600
        let mins  = (total % 3600) / 60
        let secs  = total % 60
        if days >= 7 { return .days(days) }
        if days >= 1 { return .daysHoursMinutes(days, hours, mins) }
        if hours >= 1 { return .hoursMinutes(hours, mins) }
        return .minutesSeconds(mins, secs)
    }

    var timeToNextMilestone: String {
        if fastingPhase == .freedom { return "Living in freedom" }
        let remaining = fastingPhase.nextThreshold - elapsedSeconds
        let h = Int(remaining) / 3600
        let m = (Int(remaining) % 3600) / 60
        if h >= 24 { return "\(h / 24)d \(h % 24)h away" }
        if h > 0 { return "\(h)h \(m)m away" }
        return "\(m)m away"
    }

    // MARK: Weekly Insight Data

    var weeklyInsight: WeeklyInsight? {
        let weekAgo = Date().addingTimeInterval(-7 * 86400)
        let recentResets = resetEvents.filter { $0.date > weekAgo }
        let recentCravings = cravingLogs.filter { $0.date > weekAgo }

        guard !recentResets.isEmpty || !recentCravings.isEmpty else { return nil }

        let longest = recentResets.map(\.fastDuration).max() ?? elapsedSeconds
        let topTrigger = mostCommonTrigger(in: recentCravings)

        let copy = weeklyInsightCopy(
            resets: recentResets.count,
            longestFast: longest,
            topTrigger: topTrigger,
            recentResets: recentResets
        )

        return WeeklyInsight(
            longestFast: longest,
            resetCount: recentResets.count,
            topTrigger: topTrigger,
            insightCopy: copy
        )
    }

    private func mostCommonTrigger(in logs: [CravingLog]) -> CravingTrigger? {
        var counts: [CravingTrigger: Int] = [:]
        logs.forEach { counts[$0.trigger, default: 0] += 1 }
        return counts.max(by: { $0.value < $1.value })?.key
    }

    private func weeklyInsightCopy(
        resets: Int,
        longestFast: TimeInterval,
        topTrigger: CravingTrigger?,
        recentResets: [ResetEvent]
    ) -> String {
        if resets == 0 {
            let days = Int(longestFast / 86400)
            return "Zero resets this week. \(days > 0 ? "\(days) days and counting." : "You're on a clean run.") That's not common. Keep building on it."
        }

        let eveningResets = recentResets.filter {
            let h = Calendar.current.component(.hour, from: $0.date)
            return h >= 20
        }

        if eveningResets.count == resets && resets > 1 {
            return "Both resets happened after 8pm. Your strongest window is the hour after dinner — and your most vulnerable one. The craving toolkit is there for exactly that moment."
        }

        if let trigger = topTrigger, trigger == .stress {
            return "Stress was your most common craving trigger this week. Cortisol drives glucose cravings as a quick fix. Deep breathing for 2 minutes lowers cortisol measurably."
        }

        if let trigger = topTrigger, trigger == .boredom {
            return "Boredom drove most of your cravings this week. The brain seeks dopamine through the easiest route available. A 5-minute walk produces the same effect — without the reset."
        }

        return "Your data this week shows \(resets) reset\(resets == 1 ? "" : "s"). Each one is information, not failure. Patterns reveal leverage points. Keep logging."
    }
}

struct WeeklyInsight {
    let longestFast: TimeInterval
    let resetCount: Int
    let topTrigger: CravingTrigger?
    let insightCopy: String

    var longestFastFormatted: String {
        let d = Int(longestFast) / 86400
        let h = (Int(longestFast) % 86400) / 3600
        if d > 0 { return "\(d)d \(h)h" }
        return "\(h)h"
    }
}
