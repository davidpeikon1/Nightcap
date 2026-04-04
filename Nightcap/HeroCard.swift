import SwiftUI

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

    private var trackingSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("SUGAR FREE FOR")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundStyle(Color("NCTextSecondary"))
                .padding(.bottom, 14)

            timerView

            Text(ContextualCopy.line(for: store.elapsedSeconds))
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)

            if let startDate = store.lastSugarDate {
                Button {
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
                    .padding(.top, 10)
                }
            }

            Divider()
                .background(Color("NCTextTertiary").opacity(0.5))
                .padding(.top, 16)

            Button {
                showResetModal = true
            } label: {
                Text("I just had processed sugar")
                    .font(.system(size: 14))
                    .foregroundStyle(Color("NCWarning"))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
            }
        }
    }

    // MARK: - Not-tracking state

    private var notTrackingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Not tracking yet.")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))

            Text("When you're ready, tell us when you last had processed sugar.")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                showEditStart = true
            } label: {
                Text("Start tracking")
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
        .accessibilityHint("Sugar-free elapsed time")
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
