import SwiftUI

// MARK: - Reset Modal

struct ResetModal: View {
    @EnvironmentObject var store: FastingStore
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var note: String = ""
    @State private var didConfirm = false
    // Captures elapsed + badges before the reset fires so the near-miss
    // calculation has the pre-reset state available in confirmationView.
    @State private var preResetElapsed: TimeInterval = 0
    @State private var preResetBadges: Set<BadgeID> = []

    var body: some View {
        ZStack {
            Color("NCBackground").ignoresSafeArea()

            if didConfirm {
                resetConfirmationView
            } else {
                resetFormView
            }
        }
        .animation(.easeInOut(duration: 0.28), value: didConfirm)
        .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
    }

    /// Loss-aversion title — surfaces what's being given up before confirming.
    private var resetTitle: String {
        let days = Int(store.elapsedSeconds / 86400)
        let h    = Int(store.elapsedSeconds / 3600)
        if days >= 7 { return "You're about to reset \(days) days." }
        if days >= 2 { return "You're \(days) days in." }
        if days == 1 { return "You're 1 day in." }
        if h >= 1    { return "You're \(h) hour\(h == 1 ? "" : "s") in." }
        return "Starting fresh."
    }

    /// Detects if the current reset is happening during a time-of-day or weekday
    /// pattern that has shown up before — surfaces the pattern without lecturing.
    private var timingPatternNote: String? {
        let resets = store.resetEvents
        guard resets.count >= 3 else { return nil }
        let cal  = Calendar.current
        let hour = cal.component(.hour, from: Date())

        // Evening window (6pm–11pm) — the highest-risk window for most users.
        if (18...23).contains(hour) {
            let eveningCount = resets.filter {
                (18...23).contains(cal.component(.hour, from: $0.date))
            }.count
            if eveningCount >= 2, eveningCount * 2 >= resets.count {
                return "\(eveningCount) of your \(resets.count) resets happened in the evening. This is that window."
            }
        }

        // Weekday pattern — same day of week appearing 2+ times out of 4+ total.
        let weekday = cal.component(.weekday, from: Date())
        let sameWeekdayCount = resets.filter {
            cal.component(.weekday, from: $0.date) == weekday
        }.count
        if sameWeekdayCount >= 2, resets.count >= 4, sameWeekdayCount * 3 >= resets.count {
            let days = ["", "Sundays", "Mondays", "Tuesdays", "Wednesdays",
                        "Thursdays", "Fridays", "Saturdays"]
            return "\(sameWeekdayCount) of your \(resets.count) resets have happened on \(days[weekday]). Worth noting."
        }

        return nil
    }

    /// Context-aware body copy based on how long the current fast ran.
    private var resetSubtitle: String {
        let h = store.elapsedSeconds / 3600
        switch h {
        case ..<1:
            return "Everyone resets. The first hour is the highest-risk window — and you made it this far."
        case 1..<24:
            return "A few hours in. The fast showed you where the hard moments are. That's data worth keeping."
        case 24..<72:
            return "Every reset is information. What triggered this one is worth noting before you clock back in."
        case 72..<336:
            return "Days in and then a reset — that's where the behavioral pattern lives. The note field is worth using."
        default:
            return "That was a real streak. What you built in those days doesn't reverse overnight — the biology doesn't work that way."
        }
    }

    private var resetFormView: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text(resetTitle)
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(Color("NCTextPrimary"))

                Text(resetSubtitle)
                    .font(.system(size: 15))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .lineSpacing(4)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("NOTE")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(1.5)
                    .foregroundStyle(Color("NCTextTertiary"))

                TextField("e.g. birthday cake, work stress, social pressure", text: $note)
                    .font(.system(size: 15))
                    .foregroundStyle(Color("NCTextPrimary"))
                    .padding(14)
                    .background(Color("NCSurface"))
                    .cornerRadius(10)
                    .submitLabel(.done)
                    .onSubmit {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .onChange(of: note) { _, v in
                        if v.count > 120 { note = String(v.prefix(120)) }
                    }

                if note.count > 80 {
                    HStack {
                        Spacer()
                        Text("\(note.count) / 120")
                            .font(.system(size: 11))
                            .foregroundStyle(
                                note.count > 110 ? Color("NCWarning") : Color("NCTextTertiary")
                            )
                    }
                    .padding(.top, 2)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: note.count > 80)
                }
            }

            // Timing pattern — shows if this reset fits a recurring time-of-day or
            // weekday pattern. Informs rather than shames; tertiary color matches tone.
            if let pattern = timingPatternNote {
                HStack(alignment: .top, spacing: 12) {
                    Rectangle()
                        .fill(Color("NCWarning").opacity(0.4))
                        .frame(width: 2)
                        .cornerRadius(1)
                    Text(pattern)
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Color("NCTextTertiary"))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Badge proximity warning — shown when the user is 60%+ toward
            // the next badge. Shown in green to frame it as opportunity, not shame.
            // This is the highest-leverage loss-aversion moment: seeing "3h from 1 Week"
            // before confirming is the last meaningful pause before the reset.
            if let proximity = formBadgeProximityText {
                HStack(alignment: .top, spacing: 12) {
                    Rectangle()
                        .fill(Color("NCSuccess").opacity(0.5))
                        .frame(width: 2)
                        .cornerRadius(1)
                    Text(proximity)
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Color("NCSuccess").opacity(0.8))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Commitment reminder — surfaces the user's stated reason at the
            // moment they're about to reset (Cialdini: commitment & consistency).
            // Rendered only when a goal is set; kept in tertiary color so it
            // informs without guilting.
            if let goal = appState.userGoal {
                HStack(alignment: .top, spacing: 12) {
                    Rectangle()
                        .fill(Color("NCTextTertiary").opacity(0.5))
                        .frame(width: 2)
                        .cornerRadius(1)
                    Text(goal.resetMomentReminder)
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Color("NCTextTertiary"))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Sugar avoided — concrete biological progress already in the body.
            // "That doesn't reset" reframes a reset from total loss to partial win.
            if let g = appState.dailySugarGrams, g > 0, store.elapsedSeconds >= 3600 {
                let days = max(1, Int(store.elapsedSeconds / 86400))
                let avoided = days * g
                HStack(alignment: .top, spacing: 12) {
                    Rectangle()
                        .fill(Color("NCSuccess").opacity(0.4))
                        .frame(width: 2)
                        .cornerRadius(1)
                    Text("This fast already kept ~\(avoided)g of added sugar out of your body. That doesn't reset.")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Color("NCSuccess").opacity(0.75))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    preResetElapsed = store.elapsedSeconds
                    preResetBadges  = store.earnedBadges
                    store.logSugar(note: note.isEmpty ? nil : note)
                    withAnimation { didConfirm = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        dismiss()
                    }
                } label: {
                    Text("Restart my fast")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color("NCBackground"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color("NCAccent"))
                        .cornerRadius(12)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.system(size: 14))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .padding(.vertical, 8)
                }
            }
        }
        .padding(24)
    }

    /// Pre-confirmation badge proximity — shown in the form before the user confirms.
    /// Surfaced when 60%+ toward the next badge, framed as opportunity (green).
    private var formBadgeProximityText: String? {
        guard store.isTracking else { return nil }
        guard let nextBadge = BadgeID.allCases.first(where: { !store.earnedBadges.contains($0) }) else { return nil }
        let remaining = nextBadge.threshold - store.elapsedSeconds
        let pct = store.elapsedSeconds / nextBadge.threshold
        guard pct >= 0.6, remaining > 60 else { return nil }
        let h = Int(remaining) / 3600
        let m = (Int(remaining) % 3600) / 60
        let d = h / 24
        let timeLabel: String = {
            if d > 0 { let rh = h % 24; return rh > 0 ? "\(d)d \(rh)h" : "\(d)d" }
            if h > 0 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
            return m == 1 ? "1 minute" : "\(m) minutes"
        }()
        return "\(timeLabel) from \(nextBadge.label)."
    }

    /// Context-aware spotlight line — reduces shame and normalizes resets.
    /// Varies by total reset count so it doesn't feel canned on repeat visits.
    private var spotlightLine: String {
        switch store.resetEvents.count {
        case 1:
            return "First one logged. Knowing where it happened is already more than most people do."
        case 2:
            return "Every reset is data. Two data points start a pattern."
        case 3:
            return "Three resets is enough data to see something. Check the times and triggers."
        case 4...6:
            return "The pattern is somewhere in those logs. It usually takes a few resets to see it."
        case 7...10:
            return "Everyone who has broken this habit has a reset history that looks like yours."
        default:
            return "Every reset is data. No one is tracking but you."
        }
    }

    /// Near-miss: shown when the user was ≥60% toward the next badge.
    /// Uses pre-reset state so the calculation survives the elapsed reset.
    private var nearMissText: String? {
        guard preResetElapsed > 0 else { return nil }
        guard let nextBadge = BadgeID.allCases.first(where: { !preResetBadges.contains($0) }) else { return nil }
        let shortfall = nextBadge.threshold - preResetElapsed
        let pct = preResetElapsed / nextBadge.threshold
        guard pct >= 0.6, shortfall > 60 else { return nil }
        let totalH = Int(shortfall / 3600)
        let d = totalH / 24; let h = totalH % 24
        if d > 0 { return "\(d)d\(h > 0 ? " \(h)h" : "") short of \(nextBadge.label)." }
        if totalH > 0 { return "\(totalH)h short of \(nextBadge.label)." }
        let m = max(1, Int(shortfall / 60))
        return "\(m)m short of \(nextBadge.label)."
    }

    private var resetConfirmationView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color("NCSuccess"))

            Text("Reset logged.")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))

            // Near-miss effect — plants the seed for the next attempt
            if let miss = nearMissText {
                Text(miss)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color("NCWarning").opacity(0.85))
                    .multilineTextAlignment(.center)
            }

            // Spotlight effect — reduce shame, normalize the experience.
            // Copy varies by reset count so it doesn't feel canned on repeat visits.
            Text(spotlightLine)
                .font(.system(size: 14))
                .foregroundStyle(Color("NCTextSecondary"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
        .transition(.opacity)
    }
}

// MARK: - Edit Start Time Sheet

struct EditStartTimeSheet: View {
    @EnvironmentObject var store: FastingStore
    @Environment(\.dismiss) var dismiss

    @State private var selectedDate: Date = Date()

    var body: some View {
        ZStack {
            Color("NCBackground").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit start time")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))

                    Text("When did you actually last have processed sugar?")
                        .font(.system(size: 15))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .lineSpacing(4)
                }

                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(Color("NCAccent"))
                .labelsHidden()

                Spacer()

                VStack(spacing: 12) {
                    Button {
                        store.setInitialDate(at: selectedDate)
                        dismiss()
                    } label: {
                        Text("Save")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color("NCBackground"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color("NCAccent"))
                            .cornerRadius(12)
                    }

                    Button { dismiss() } label: {
                        Text("Cancel")
                            .font(.system(size: 14))
                            .foregroundStyle(Color("NCTextSecondary"))
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            // Pre-populate with the existing start time if editing, or default
            // to this morning (start of today) for a first-time setup so the
            // user has to consciously scroll forward rather than accidentally
            // saving "right now" as their last sugar time.
            selectedDate = store.lastSugarDate ?? Calendar.current.startOfDay(for: Date())
        }
    }
}
