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

            // Spotlight effect — reduce shame, normalize the experience
            Text("Every reset is data. No one is tracking but you.")
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
