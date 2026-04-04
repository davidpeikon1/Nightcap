import SwiftUI
import UIKit

/// The primary card on the home screen.
/// Leads with the daily reframe quote (the "why"), then flows directly into
/// the timer and action (the "how"). Both are visible without scrolling.
struct HeroCard: View {
    @EnvironmentObject var store: FastingStore
    @State private var scienceExpanded = false
    @State private var showResetModal  = false
    @State private var showEditStart   = false

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
            Rectangle()
                .fill(Color("NCTextTertiary").opacity(0.4))
                .frame(height: 1)
                .padding(.top, 20)
                .padding(.bottom, 20)

            // ── Timer / action ─────────────────────────────────────────────
            if store.isTracking {
                trackingSection
            } else {
                notTrackingSection
            }
        }
        .padding(20)
        .background(Color("NCSurface"))
        .cornerRadius(16)
        .animation(.spring(duration: 0.3), value: scienceExpanded)
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

    // MARK: - Tracking state

    /// True only when the current fast is already the user's all-time longest.
    /// Requires at least one completed previous fast so the comparison is meaningful.
    private var isPersonalBest: Bool {
        guard store.isTracking, !store.resetEvents.isEmpty else { return false }
        let previousBest = store.resetEvents.map(\.fastDuration).max() ?? 0
        return store.elapsedSeconds > previousBest
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
                    Text("PERSONAL BEST")
                        .font(.system(size: 9, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(Color("NCSuccess"))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color("NCSuccess").opacity(0.12))
                        .cornerRadius(4)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
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

            // Show the previous fast's duration for the first 30 minutes after a reset.
            // Reframes the reset as data rather than leaving that moment in silence.
            if store.elapsedSeconds < 1_800, let lastReset = store.resetEvents.first {
                Text("Previous fast: \(formatFastDuration(lastReset.fastDuration)). \(previousFastSuffix(lastReset.fastDuration))")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color("NCTextTertiary"))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
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
                    unitBlock(value: m, unit: "m")
                }
            case .daysHoursMinutes(let d, let h, let m):
                HStack(alignment: .lastTextBaseline, spacing: 16) {
                    unitBlock(value: d, unit: "d")
                    if h > 0 { unitBlock(value: h, unit: "h") }
                    unitBlock(value: m, unit: "m")
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
    }

    private var timerA11yLabel: String {
        let total = Int(store.elapsedSeconds)
        let d = total / 86400
        let h = (total % 86400) / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        if d > 0 { return "\(d) day\(d == 1 ? "" : "s"), \(h) hour\(h == 1 ? "" : "s")" }
        if h > 0 { return "\(h) hour\(h == 1 ? "" : "s"), \(m) minute\(m == 1 ? "" : "s")" }
        if m > 0 { return "\(m) minute\(m == 1 ? "" : "s"), \(s) second\(s == 1 ? "" : "s")" }
        return "\(s) second\(s == 1 ? "" : "s")"
    }

    /// Context-aware suffix for the "Previous fast: X" post-reset message.
    private func previousFastSuffix(_ seconds: TimeInterval) -> String {
        let h = seconds / 3600
        if h >= 336 { return "That streak changed your biology. It doesn't reverse overnight." }
        if h >= 168 { return "A week or more before the reset. The biology of those days is still in your system." }
        if h >= 24  { return "A full day before the reset. Every hour counted." }
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

    private func monoText(_ text: String, size: CGFloat) -> Text {
        Text(text)
            .font(.system(size: size, weight: .light).monospacedDigit())
            .foregroundStyle(Color("NCTextPrimary"))
    }

    private func unitBlock(value: Int, unit: String) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 3) {
            Text("\(value)")
                .font(.system(size: 52, weight: .light).monospacedDigit())
                .foregroundStyle(Color("NCTextPrimary"))
            Text(unit)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
                .padding(.bottom, 5)
        }
    }
}
