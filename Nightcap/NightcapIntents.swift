import AppIntents
import Foundation

// MARK: - Siri Phrases / Shortcuts Provider

struct NightcapShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetFastingStatusIntent(),
            phrases: [
                "How long have I been sugar free in \(.applicationName)",
                "Check my fast in \(.applicationName)",
                "What phase am I in on \(.applicationName)",
                "How's my Nightcap fast going",
            ],
            shortTitle: "Get Sugar-Free Time",
            systemImageName: "timer"
        )
        AppShortcut(
            intent: GetNextMilestoneIntent(),
            phrases: [
                "How far to my next milestone in \(.applicationName)",
                "When's my next \(.applicationName) milestone",
            ],
            shortTitle: "Next Milestone",
            systemImageName: "flag"
        )
    }
}

// MARK: - Get Fasting Status

struct GetFastingStatusIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Sugar-Free Time"
    static let description = IntentDescription(
        "Check how long you've been sugar free and which phase you're in.",
        categoryName: "Information"
    )
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {
        let store = SharedFastData.load()
        guard let elapsed = store.elapsed else {
            return .result(
                value: "Not tracking",
                dialog: IntentDialog("You haven't started tracking yet. Open Nightcap to begin.")
            )
        }
        let time  = formatElapsed(elapsed)
        let phase = phaseLabel(for: elapsed)
        return .result(
            value: time,
            dialog: IntentDialog("You've been sugar free for \(time). You're in the \(phase) phase.")
        )
    }
}

// MARK: - Get Next Milestone

struct GetNextMilestoneIntent: AppIntent {
    static let title: LocalizedStringResource = "Next Milestone"
    static let description = IntentDescription(
        "Find out how long until your next Nightcap milestone.",
        categoryName: "Information"
    )
    static let openAppWhenRun = false

    @MainActor
    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {
        let store = SharedFastData.load()
        guard let elapsed = store.elapsed else {
            return .result(
                value: "Not tracking",
                dialog: IntentDialog("Open Nightcap to start your fast first.")
            )
        }
        let milestone = nextMilestone(for: elapsed)
        if milestone == "Living in freedom" {
            return .result(
                value: milestone,
                dialog: IntentDialog("You're in the Freedom phase — living sugar free. Keep going.")
            )
        }
        return .result(
            value: milestone,
            dialog: IntentDialog("Your next milestone is \(milestone) away.")
        )
    }
}

// MARK: - Shared data helper (reads from App Group — no dependency on FastingStore)

private struct SharedFastData {
    let elapsed: TimeInterval?

    static func load() -> SharedFastData {
        let defaults = UserDefaults(suiteName: "group.com.nightcap.app") ?? .standard
        guard let last = defaults.object(forKey: "lastSugarDate") as? Date else {
            return SharedFastData(elapsed: nil)
        }
        return SharedFastData(elapsed: max(0, Date().timeIntervalSince(last)))
    }
}

// MARK: - Formatting helpers

private func formatElapsed(_ s: TimeInterval) -> String {
    let total = Int(s)
    let d = total / 86400
    let h = (total % 86400) / 3600
    let m = (total % 3600) / 60
    if d >= 7 { return "\(d) days" }
    if d >= 1 {
        return h > 0
            ? "\(d) day\(d == 1 ? "" : "s") and \(h) hour\(h == 1 ? "" : "s")"
            : "\(d) day\(d == 1 ? "" : "s")"
    }
    if h >= 1 {
        return m > 0
            ? "\(h) hour\(h == 1 ? "" : "s") and \(m) minute\(m == 1 ? "" : "s")"
            : "\(h) hour\(h == 1 ? "" : "s")"
    }
    return "\(m) minute\(m == 1 ? "" : "s")"
}

private func phaseLabel(for elapsed: TimeInterval) -> String {
    let h = elapsed / 3600
    switch h {
    case ..<1:      return "Starting Out"
    case 1..<24:    return "First Day"
    case 24..<72:   return "Withdrawal"
    case 72..<168:  return "Breakthrough"
    case 168..<336: return "Rewiring"
    default:        return "Freedom"
    }
}

private func nextMilestone(for elapsed: TimeInterval) -> String {
    let h = elapsed / 3600
    if h >= 336 { return "Living in freedom" }
    let remaining: TimeInterval = {
        switch h {
        case ..<1:      return 3_600    - elapsed
        case 1..<24:    return 86_400   - elapsed
        case 24..<72:   return 259_200  - elapsed
        case 72..<168:  return 604_800  - elapsed
        default:        return 1_209_600 - elapsed
        }
    }()
    let rh = Int(remaining) / 3600
    let rm = (Int(remaining) % 3600) / 60
    if rh >= 24 { return "\(rh / 24) day\(rh / 24 == 1 ? "" : "s") and \(rh % 24) hour\(rh % 24 == 1 ? "" : "s")" }
    if rh > 0   { return "\(rh) hour\(rh == 1 ? "" : "s") and \(rm) minute\(rm == 1 ? "" : "s")" }
    return "\(rm) minute\(rm == 1 ? "" : "s")"
}
