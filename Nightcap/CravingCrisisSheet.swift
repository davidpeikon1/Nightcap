import SwiftUI
import Combine

// MARK: - Craving Crisis Sheet
//
// Crisis-mode tool. Opens from the floating "I'm craving" button on HomeView.
// Leads with a random reframe to interrupt the craving response, then gives
// immediate access to the 20-minute timer and a quick-log action.

struct CravingCrisisSheet: View {
    @EnvironmentObject var store: FastingStore
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @StateObject private var countdown = CountdownState()
    @State private var cardText: String
    @State private var cardIndex: Int

    init() {
        let result = QuoteLibrary.randomCravingCard(excluding: nil)
        _cardText  = State(initialValue: result.text)
        _cardIndex = State(initialValue: result.index)
    }

    var body: some View {
        // System drag indicator is shown via .presentationDragIndicator(.visible)
        // in HomeView — no custom capsule needed here.
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                EmptyView().frame(height: 4) // minimal top breathing room

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("The craving has a ceiling.")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(Color("NCTextPrimary"))
                        Text("It passes in under 20 minutes. Every time.")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Color("NCTextSecondary"))
                    }
                    .padding(.horizontal, 24)

                    // Reframe card
                    reframeCard

                    // 20-minute timer — always visible, no toggle
                    timerSection

                    // Quick log
                    logSection

                    Spacer(minLength: 40)
                }
            }
        .background(Color("NCBackground").ignoresSafeArea())
        .onDisappear { countdown.stop() }
    }

    // MARK: - Reframe Card

    private var reframeCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("REFRAME")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Color("NCTextSecondary"))
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    let result = QuoteLibrary.randomCravingCard(excluding: cardIndex)
                    withAnimation(.easeInOut(duration: 0.2)) {
                        cardText  = result.text
                        cardIndex = result.index
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .light))
                        Text("New one")
                            .font(.system(size: 12, weight: .regular))
                    }
                    .foregroundStyle(Color("NCSuccess"))
                }
            }

            Text(cardText)
                .id(cardIndex)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .transition(.opacity)
        }
        .padding(20)
        .background(Color("NCSurface"))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }

    // MARK: - Timer Section (always visible — no toggle)

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("20 MINUTES")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Color("NCTextSecondary"))
                Spacer()
                Text("cravings always pass")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Color("NCTextTertiary"))
            }

            if countdown.completed {
                completedState
            } else {
                countdownDisplay
                timerControls
            }
        }
        .padding(20)
        .background(Color("NCSurface"))
        .cornerRadius(16)
        .padding(.horizontal, 24)
        .animation(.spring(duration: 0.3), value: countdown.completed)
    }

    private var countdownDisplay: some View {
        let m = countdown.secondsLeft / 60
        let s = countdown.secondsLeft % 60
        return HStack(alignment: .lastTextBaseline, spacing: 4) {
            Text(String(format: "%02d", m))
                .font(.system(size: 52, weight: .light).monospacedDigit())
                .foregroundStyle(Color("NCTextPrimary"))
                .contentTransition(.numericText())
            Text(":")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(Color("NCTextTertiary"))
            Text(String(format: "%02d", s))
                .font(.system(size: 52, weight: .light).monospacedDigit())
                .foregroundStyle(Color("NCTextPrimary"))
                .contentTransition(.numericText())
        }
        .animation(.snappy(duration: 0.25), value: countdown.secondsLeft)
        .frame(maxWidth: .infinity)
    }

    private var timerControls: some View {
        HStack(spacing: 12) {
            if countdown.isRunning {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    countdown.stop()
                } label: {
                    Text("Pause")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color("NCTextPrimary"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color("NCBackground"))
                        .cornerRadius(10)
                }
            } else {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    countdown.start()
                } label: {
                    Text(countdown.secondsLeft == 20 * 60 ? "Start the clock" : "Resume")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color("NCBackground"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color("NCAccent"))
                        .cornerRadius(10)
                }

                if countdown.secondsLeft < 20 * 60 {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        countdown.reset()
                    } label: {
                        Text("Reset")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color("NCTextSecondary"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color("NCBackground"))
                            .cornerRadius(10)
                    }
                }
            }
        }
    }

    private var completedState: some View {
        VStack(spacing: 8) {
            Text("20 minutes. The craving passed.")
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))
                .multilineTextAlignment(.center)
            let total = UserDefaults.standard.integer(forKey: "countdown.completions")
            if total > 1 {
                Text("\(total) times you've outlasted it.")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color("NCSuccess"))
            }
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                countdown.reset()
            } label: {
                Text("Done")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("NCBackground"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color("NCAccent"))
                    .cornerRadius(10)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Log Section

    private var logSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("WHAT HAPPENED?")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundStyle(Color("NCTextSecondary"))

            VStack(spacing: 10) {
                logButton(
                    label: "I resisted",
                    sublabel: "The craving passed.",
                    color: Color("NCSuccess")
                ) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    dismiss()
                }

                logButton(
                    label: "I had some sugar",
                    sublabel: "Log a reset and restart the clock.",
                    color: Color("NCTextSecondary")
                ) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        NotificationCenter.default.post(name: .nightcapOpenResetModal, object: nil)
                    }
                }

                logButton(
                    label: "Still in it",
                    sublabel: "Stay here. Keep the timer going.",
                    color: Color("NCWarning")
                ) {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    if countdown.completed {
                        countdown.reset()
                        countdown.start()
                    } else if !countdown.isRunning {
                        countdown.start()
                    }
                }
            }
        }
        .padding(20)
        .background(Color("NCSurface"))
        .cornerRadius(16)
        .padding(.horizontal, 24)
    }

    private func logButton(
        label: String,
        sublabel: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(color)
                    Text(sublabel)
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color("NCTextTertiary"))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Color("NCTextTertiary").opacity(0.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color("NCBackground"))
            .cornerRadius(10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
