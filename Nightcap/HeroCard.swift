import SwiftUI
import UIKit

/// The primary card on the home screen.
/// Leads with the daily reframe quote (the "why"), then flows directly into
/// the timer and action (the "how"). Both are visible without scrolling.
struct HeroCard: View {
    @EnvironmentObject var store: FastingStore
    @AppStorage("timerSectionExpanded") private var timerExpanded = false
    @State private var scienceExpanded = false
    @State private var showResetModal  = false
    @State private var showEditStart   = false

    /// Subtle phase-based tint layered over the card surface.
    /// Communicates biological progress through colour without stating it.
    private var phaseAmbientColor: Color {
        switch store.fastingPhase {
        case .justStarted:  return .clear
        case .firstDay:     return Color("NCWarning").opacity(0.04)
        case .withdrawal:   return Color.red.opacity(0.04)
        case .breakthrough: return Color.orange.opacity(0.035)
        case .rewiring:     return Color.teal.opacity(0.04)
        case .freedom:      return Color("NCSuccess").opacity(0.05)
        }
    }

    private var quote: ReframeQuote {
        QuoteLibrary.dailyQuote(for: store.elapsedSeconds)
    }

    private var dayCount: Int {
        max(1, Int(store.elapsedSeconds / 86400) + 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // ── Quote ──────────────────────────────────────────────────────
            HStack {
                Text("TODAY'S REFRAME")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Color("NCTextSecondary"))
                Spacer()
                if store.isTracking {
                    Text("day \(dayCount)")
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(Color("NCTextTertiary"))
                }
            }

            Rectangle()
                .fill(Color("NCTextTertiary").opacity(0.4))
                .frame(height: 1)
                .padding(.top, 12)
                .padding(.bottom, 18)

            Text(quote.text)
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                withAnimation(.spring(duration: 0.3)) { scienceExpanded.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Text("The science")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color("NCSuccess"))
                    Image(systemName: scienceExpanded ? "chevron.up" : "chevron.right")
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(Color("NCSuccess"))
                }
                .padding(.top, 16)
            }

            if scienceExpanded {
                Text(quote.science)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // ── Divider between quote and timer ────────────────────────────
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                withAnimation(.spring(duration: 0.35)) { timerExpanded.toggle() }
            } label: {
                HStack {
                    Rectangle()
                        .fill(Color("NCTextTertiary").opacity(0.4))
                        .frame(height: 1)

                    if !timerExpanded, store.isTracking {
                        Text(compactTimerLine)
                            .font(.system(size: 12, weight: .light, design: .monospaced))
                            .foregroundStyle(Color("NCTextTertiary"))
                            .lineLimit(1)
                            .layoutPriority(1)
                    }

                    Image(systemName: timerExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color("NCTextTertiary").opacity(0.8))
                }
            }
            .padding(.top, 20)
            .padding(.bottom, timerExpanded ? 20 : 4)

            // ── Timer / action ─────────────────────────────────────────────
            if timerExpanded {
                if store.isTracking {
                    trackingSection
                } else {
                    notTrackingSection
                }
            }
        }
        .padding(20)
        .background(
            ZStack {
                Color("NCSurface")
                phaseAmbientColor
                    .animation(.easeInOut(duration: 2.5), value: store.fastingPhase)
            }
        )
        .cornerRadius(16)
        .animation(.spring(duration: 0.3), value: scienceExpanded)
        .animation(.spring(duration: 0.35), value: timerExpanded)
        .animation(.spring(duration: 0.3), value: store.isTracking)
        .sheet(isPresented: $showResetModal) {
            ResetModal()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showEditStart) {
            EditStartTimeSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Compact timer one-liner (shown when timer section is collapsed)

    private var compactTimerLine: String {
        let total = Int(store.elapsedSeconds)
        let d = total / 86400
        let h = (total % 86400) / 3600
        let m = (total % 3600) / 60
        var timeStr: String
        if d > 0 {
            timeStr = h > 0 ? "\(d)d \(h)h" : "\(d)d"
        } else if h > 0 {
            timeStr = m > 0 ? "\(h)h \(m)m" : "\(h)h"
        } else {
            timeStr = m > 0 ? "\(m)m" : "< 1m"
        }
        return "\(timeStr) · \(store.fastingPhase.rawValue)"
    }

    // MARK: - Tracking state

    /// True only when the current fast is already the user's all-time longest.
    /// Requires at least one completed previous fast so the comparison is meaningful.
    private var isPersonalBest: Bool {
        guard store.isTracking, !store.resetEvents.isEmpty else { return false }
        let previousBest = store.resetEvents.map(\.fastDuration).max() ?? 0
        return store.elapsedSeconds > previousBest
    }

    /// Seconds remaining until the user beats their personal best.
    /// Returns nil when already past it, when there's no prior fast, or when more than 2 h away.
    private var distanceToPB: TimeInterval? {
        guard store.isTracking, !store.resetEvents.isEmpty else { return nil }
        let best = store.resetEvents.map(\.fastDuration).max() ?? 0
        let shortfall = best - store.elapsedSeconds
        guard shortfall > 0, shortfall <= 7_200 else { return nil }
        return shortfall
    }

    private func pbApproachLabel(_ shortfall: TimeInterval) -> String {
        let h = Int(shortfall) / 3600
        let m = max(1, (Int(shortfall) % 3600) / 60)
        if h > 0 { return "\(h)H \(m)M TO PB" }
        return "\(m)M TO PB"
    }

    /// Quiet milestone label for first-ever fasts (no previous resets).
    /// Shown only when the user has never reset before — distinct from badge milestones,
    /// which are transient pop-ups. This is a persistent in-card acknowledgment.
    private var firstTimeMilestoneLabel: String? {
        guard store.resetEvents.isEmpty, store.isTracking else { return nil }
        let days  = Int(store.elapsedSeconds / 86400)
        let hours = Int(store.elapsedSeconds / 3600)
        if days >= 30  { return "Your first month." }
        if days >= 14  { return "Two weeks." }
        if days >= 7   { return "Your first week." }
        if days >= 3   { return "Three days." }
        if hours >= 24 { return "Your first day." }
        return nil
    }

    /// True when the user has a streak worth protecting and the current hour
    /// falls in the highest-risk evening window (6pm–11pm).
    private var shouldShowStreakWarning: Bool {
        guard store.streakDays >= 3, store.isTracking else { return false }
        let hour = Calendar.current.component(.hour, from: Date())
        return (18...23).contains(hour)
    }

    private var trackingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text("SUGAR FREE FOR")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Color("NCTextSecondary"))

                Spacer()

                if isPersonalBest {
                    PersonalBestBadge(label: "PERSONAL BEST", tint: Color("NCSuccess"))
                } else if let shortfall = distanceToPB {
                    PersonalBestBadge(label: pbApproachLabel(shortfall), tint: Color("NCWarning"))
                }
            }
            .padding(.bottom, 14)
            .animation(.spring(duration: 0.4), value: isPersonalBest)

            timerView

            Text(ContextualCopy.line(for: store.elapsedSeconds))
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)

            // First-ever fast milestone — quiet, persistent acknowledgment that
            // a genuine "first" is happening. Distinct from badge pop-ups.
            if let milestone = firstTimeMilestoneLabel {
                Text(milestone)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color("NCSuccess").opacity(0.8))
                    .padding(.top, 2)
                    .transition(.opacity)
            }

            // Streak protection — Loss Aversion: surfacing what's at stake when
            // the user is in the window where most streaks end.
            if shouldShowStreakWarning {
                Text("Your \(store.streakDays)-day streak is in the window where most resets happen. Tonight is the one that counts.")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color("NCWarning").opacity(0.8))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
                    .transition(.opacity)
            }

            // Post-reset recovery arc — shown for the first 30 minutes after a reset.
            // "Back on the clock." for the first 2 minutes, then the previous fast
            // duration + a recovery reframe for the rest of the 30-minute window.
            if store.elapsedSeconds < 1_800, let lastReset = store.resetEvents.first {
                VStack(alignment: .leading, spacing: 4) {
                    if store.elapsedSeconds < 120 {
                        Text("Back on the clock.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color("NCTextPrimary"))
                            .transition(.opacity)
                    }
                    Text("Previous fast: \(formatFastDuration(lastReset.fastDuration)). \(previousFastSuffix(lastReset.fastDuration))")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Color("NCTextTertiary"))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 6)
                .transition(.opacity)
            }

            // Day-specific biological fact — anchors the user to where they specifically are.
            // Only shows from day 2 onward; day 1 is already well-served by the zero-to-thirty
            // and first-day tier content.
            if dayCount >= 2, let fact = QuoteLibrary.dayContextFact(for: dayCount) {
                Text(fact)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color("NCTextTertiary"))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, store.elapsedSeconds < 1_800 && !store.resetEvents.isEmpty ? 4 : 6)
                    .transition(.opacity)
            }

            if let startDate = store.lastSugarDate {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showEditStart = true
                } label: {
                    HStack(spacing: 4) {
                        Text("Started")
                            .font(.system(size: 12))
                        Text(startDate, style: .relative)
                            .font(.system(size: 12))
                        Text("ago")
                            .font(.system(size: 12))
                        Image(systemName: "pencil")
                            .font(.system(size: 9, weight: .light))
                            .opacity(0.6)
                    }
                    .foregroundStyle(Color("NCTextTertiary"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)
                    .padding(.bottom, 4)
                    .contentShape(Rectangle())
                }
            }

            Divider()
                .background(Color("NCTextTertiary").opacity(0.5))
                .padding(.top, 16)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showResetModal = true
            } label: {
                Text("Log a reset")
                    .font(.system(size: 14))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                    .contentShape(Rectangle())
            }
        }
    }

    // MARK: - Not-tracking state

    private var notTrackingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Not tracking.")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))

            if let lastReset = store.resetEvents.first {
                Text("Last fast: \(formatFastDuration(lastReset.fastDuration)).")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color("NCTextTertiary"))
            }

            Text("Set the clock to when you last had processed sugar.")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showEditStart = true
            } label: {
                Text("Set the clock")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color("NCBackground"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("NCAccent"))
                    .cornerRadius(12)
            }
            .padding(.top, 6)
        }
    }

    // MARK: - Timer display

    @ViewBuilder
    private var timerView: some View {
        Group {
            switch store.timerDisplay {
            case .minutesSeconds(let m, let s):
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    monoText(String(format: "%02d", m), size: 52)
                    monoText(":", size: 44).foregroundStyle(Color("NCTextTertiary"))
                    monoText(String(format: "%02d", s), size: 52)
                }
            case .hoursMinutes(let h, let m):
                HStack(alignment: .lastTextBaseline, spacing: 16) {
                    unitBlock(value: h, unit: "h")
                    if m > 0 { unitBlock(value: m, unit: "m") }
                }
            case .daysHoursMinutes(let d, let h, let m):
                HStack(alignment: .lastTextBaseline, spacing: 16) {
                    unitBlock(value: d, unit: "d")
                    if h > 0 { unitBlock(value: h, unit: "h") }
                    if m > 0 { unitBlock(value: m, unit: "m") }
                }
            case .days(let d):
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    monoText("\(d)", size: 64)
                    Text("days")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .padding(.bottom, 6)
                }
            }
        }
        .accessibilityLabel(timerA11yLabel)
        // numericText transition needs an animation context to interpolate.
        .animation(.snappy(duration: 0.25), value: store.elapsedSeconds)
    }

    private var timerA11yLabel: String {
        let total = Int(store.elapsedSeconds)
        let d = total / 86400
        let h = (total % 86400) / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if d > 0 { return h > 0 ? "\(d) day\(d == 1 ? "" : "s"), \(h) hour\(h == 1 ? "" : "s")" : "\(d) day\(d == 1 ? "" : "s")" }
        if h > 0 { return m > 0 ? "\(h) hour\(h == 1 ? "" : "s"), \(m) minute\(m == 1 ? "" : "s")" : "\(h) hour\(h == 1 ? "" : "s")" }
        if m > 0 { return "\(m) minute\(m == 1 ? "" : "s"), \(s) second\(s == 1 ? "" : "s")" }
        return "\(s) second\(s == 1 ? "" : "s")"
    }

    /// Context-aware suffix for the "Previous fast: X" post-reset message.
    private func previousFastSuffix(_ seconds: TimeInterval) -> String {
        let h = seconds / 3600
        if h >= 720 { return "Over a month. Those biological changes don't reverse on a reset. The work is still in your system." }
        if h >= 336 { return "That streak changed your biology. It doesn't reverse overnight." }
        if h >= 168 { return "A week or more before the reset. The biology of those days is still in your system." }
        if h >= 72  { return "Three or more days in. The dopamine recalibration that started has not reversed." }
        if h >= 24  { return "A full day before the reset. Every hour counted." }
        if h >= 6   { return "Several hours in. The insulin drop was real. So was every minute of it." }
        return "That's data, not failure."
    }

    private func formatFastDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = Int(seconds) / 60
        let hours = totalMinutes / 60
        let days  = hours / 24
        if days > 0 { return days == 1 ? "1 day" : "\(days) days" }
        if hours > 0 { return hours == 1 ? "1 hour" : "\(hours) hours" }
        if totalMinutes > 0 { return totalMinutes == 1 ? "1 minute" : "\(totalMinutes) minutes" }
        return "< 1 minute"
    }

    private func monoText(_ text: String, size: CGFloat) -> some View {
        Text(text)
            .font(.system(size: size, weight: .light).monospacedDigit())
            .foregroundStyle(Color("NCTextPrimary"))
            .contentTransition(.numericText())
    }

    private func unitBlock(value: Int, unit: String) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 3) {
            Text("\(value)")
                .font(.system(size: 52, weight: .light).monospacedDigit())
                .foregroundStyle(Color("NCTextPrimary"))
                .contentTransition(.numericText())
            Text(unit)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
                .padding(.bottom, 5)
        }
    }
}

// MARK: - Personal Best Badge

/// Extracted so it can own @State for its background pulse animation.
/// Used for both the PB-achieved (green) and PB-approaching (amber) states.
struct PersonalBestBadge: View {
    let label: String
    let tint: Color
    @State private var bgOpacity: Double = 0.12

    var body: some View {
        Text(label)
            .font(.system(size: 9, weight: .semibold))
            .tracking(1)
            .foregroundStyle(tint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(tint.opacity(bgOpacity))
            .cornerRadius(4)
            .transition(.scale(scale: 0.8).combined(with: .opacity))
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 1.8)
                    .repeatForever(autoreverses: true)
                ) {
                    bgOpacity = 0.26
                }
            }
    }
}
