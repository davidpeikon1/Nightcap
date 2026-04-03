import SwiftUI

// MARK: - Fast Tracker Card

struct FastTrackerCard: View {
    @EnvironmentObject var store: FastingStore
    @State private var showResetModal = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Label
            Text("SUGAR FREE FOR")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundStyle(Color("NCTextSecondary"))

            // Timer display
            timerView

            // Contextual copy
            Text(ContextualCopy.line(for: store.elapsedSeconds))
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Divider()
                .background(Color("NCTextTertiary").opacity(0.5))

            // Reset button (ghost)
            Button {
                showResetModal = true
            } label: {
                Text("I just had processed sugar")
                    .font(.system(size: 14))
                    .foregroundStyle(Color("NCWarning"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
        }
        .padding(20)
        .background(Color("NCSurface"))
        .cornerRadius(16)
        .sheet(isPresented: $showResetModal) {
            ResetModal()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: Timer View

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
                    unitBlock(value: h, unit: "h")
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
        .accessibilityLabel(timerAccessibilityLabel)
        .accessibilityHint("Sugar-free elapsed time")
    }

    private var timerAccessibilityLabel: String {
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
            .font(.system(size: size, weight: .light, design: .default).monospacedDigit())
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

// MARK: - Reset Modal

struct ResetModal: View {
    @EnvironmentObject var store: FastingStore
    @Environment(\.dismiss) var dismiss
    @State private var note: String = ""
    @State private var didConfirm = false

    var body: some View {
        ZStack {
            Color("NCBackground").ignoresSafeArea()

            if didConfirm {
                resetConfirmationView
            } else {
                resetFormView
            }
        }
    }

    private var resetFormView: some View {
        VStack(alignment: .leading, spacing: 28) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Starting fresh.")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(Color("NCTextPrimary"))

                Text("Everyone resets. The fact that you're tracking it puts you ahead of most people.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .lineSpacing(4)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("What was it?")
                    .font(.system(size: 12, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(Color("NCTextTertiary"))

                TextField("e.g. chocolate after dinner", text: $note)
                    .font(.system(size: 15))
                    .foregroundStyle(Color("NCTextPrimary"))
                    .padding(14)
                    .background(Color("NCSurface"))
                    .cornerRadius(10)
                    .submitLabel(.done)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
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
                    Text("I didn't actually have sugar")
                        .font(.system(size: 14))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .padding(.vertical, 8)
                }
            }
        }
        .padding(24)
    }

    private var resetConfirmationView: some View {
        VStack(spacing: 16) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))

            Text("Fast restarted.")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))

            Text("Every reset is data.")
                .font(.system(size: 14))
                .foregroundStyle(Color("NCTextSecondary"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
    }
}
