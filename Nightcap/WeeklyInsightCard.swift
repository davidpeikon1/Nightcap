import SwiftUI
import UIKit

struct WeeklyInsightCard: View {
    @EnvironmentObject var store: FastingStore
    @EnvironmentObject var appState: AppState
    @State private var isDismissed = Self.loadDismissed()

    private static let dismissKey = "weeklyInsightDismissedWeek"

    /// True if the user dismissed the card during the current ISO week.
    private static func loadDismissed() -> Bool {
        guard let savedWeek = UserDefaults.standard.object(forKey: dismissKey) as? Int else { return false }
        let cal  = Calendar.current
        let year = cal.component(.yearForWeekOfYear, from: Date())
        let week = cal.component(.weekOfYear, from: Date())
        return savedWeek == year * 100 + week
    }

    var body: some View {
        Group {
            if let insight = store.weeklyInsight, !isDismissed {
                cardView(insight)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4), value: isDismissed)
    }

    private func cardView(_ insight: WeeklyInsight) -> some View {
        let weekAgo = Date().addingTimeInterval(-7 * 86400)
        let cravingsHeld = store.cravingLogs.filter { $0.date > weekAgo }.count
        return VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("THIS WEEK")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundStyle(Color("NCTextSecondary"))

            // Stats
            VStack(spacing: 10) {
                statRow("Longest fast", value: insight.longestFastFormatted)
                statRow("Resets this week", value: "\(insight.resetCount)")
                if cravingsHeld > 0 {
                    statRow("Cravings held", value: "\(cravingsHeld)")
                }
                if store.streakDays > 0 {
                    statRow("Current streak", value: "\(store.streakDays)d")
                }
                if let trigger = insight.topTrigger {
                    statRow("Top craving trigger", value: trigger.rawValue)
                }
                // Sugar avoided this week — only shown when number is set and
                // the user has been tracking for at least 7 days.
                if let g = appState.dailySugarGrams,
                   store.elapsedSeconds >= 7 * 86400 {
                    let avoided = 7 * g
                    statRow("Added sugar avoided", value: "~\(avoided)g")
                }
            }

            Rectangle()
                .fill(Color("NCTextTertiary").opacity(0.4))
                .frame(height: 1)

            // Insight copy
            Text(insight.insightCopy)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            // Goal-specific progress line — ties the user's stated motivation
            // directly to their elapsed time, making the data personally meaningful.
            let days = Int(store.elapsedSeconds / 86400)
            if let goal = appState.userGoal, let goalLine = goalProgressInsight(for: goal, days: days) {
                Text(goalLine)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color("NCSuccess").opacity(0.75))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation { isDismissed = true }
                // Persist so the card stays dismissed for the rest of the current week.
                let cal  = Calendar.current
                let year = cal.component(.yearForWeekOfYear, from: Date())
                let week = cal.component(.weekOfYear, from: Date())
                UserDefaults.standard.set(year * 100 + week, forKey: Self.dismissKey)
            } label: {
                Text("Got it")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(Color("NCBackground"))
                    .cornerRadius(10)
            }
            .accessibilityHint("Dismisses this card for the rest of the week")
        }
        .padding(20)
        .background(Color("NCSurface"))
        .cornerRadius(16)
    }

    // MARK: - Goal-aware insight

    /// Returns a goal-personalized insight line tied to elapsed day count.
    /// Shows only after 3+ days so the insight is grounded in real progress.
    private func goalProgressInsight(for goal: UserGoal, days: Int) -> String? {
        guard days >= 3 else { return nil }
        switch goal {
        case .sleepBetter:
            if days >= 14 { return "Two weeks without glycemic disruption. Your slow-wave sleep window is deepening. The 2–4am cortisol waking has less to feed on now." }
            if days >= 7  { return "A week of stable blood sugar. Your sleep architecture has had real time to begin restoring — the restorative deep-sleep window is longer." }
            return "Three or more nights without a glucose spike means three nights of reduced cortisol waking. That's already measurable."
        case .moreEnergy:
            if days >= 14 { return "Two weeks of reduced insulin variability. The energy you feel now is closer to your actual baseline — not borrowed from future crashes." }
            if days >= 7  { return "A week of stable insulin means your afternoon energy is running on a different substrate now. The flat period is behind you." }
            return "Three days in, your cells are adapting to fat oxidation. The flat period you may feel is the transition, not your baseline."
        case .breakCravings:
            if days >= 14 { return "Two weeks. The compulsive edge that was there on day 1 is chemically resolved. What's left is habit — and habits respond to extinction." }
            if days >= 7  { return "A week of interrupting the craving pattern. The neural pathway that produced the compulsive pull is measurably weaker." }
            return "By day 3, the acute physiological pull has resolved. What's left is conditioned response — and conditioned responses weaken with each interruption."
        case .loseWeight:
            if days >= 14 { return "Two weeks of sustained insulin reduction. Visceral fat responds faster to this lever than any other dietary change." }
            if days >= 7  { return "After a week, visceral fat mobilization is underway. Fasting insulin is falling — every downstream system follows." }
            return "Three days of reduced insulin means three days of reduced fat-storage signaling. The mechanism is working."
        case .curious:
            if days >= 14 { return "Two weeks. Most people never stay in the experiment long enough to see what you're seeing now." }
            if days >= 7  { return "A week of clean data. Your n=1 trial is producing results that most people never collect." }
            return "Three days in. The data is building. How does your actual baseline feel compared to what you expected?"
        }
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color("NCTextSecondary"))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Color("NCTextPrimary"))
        }
    }
}
