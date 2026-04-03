import SwiftUI
import Combine
import UIKit

// MARK: - Countdown State (lifted so it survives tab switches)

final class CountdownState: ObservableObject {
    @Published var secondsLeft: Int = 20 * 60
    @Published var isRunning: Bool = false
    @Published var completed: Bool = false
    var timer: AnyCancellable?

    func start() {
        isRunning = true
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.secondsLeft > 0 {
                    self.secondsLeft -= 1
                } else {
                    self.stop()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    withAnimation { self.completed = true }
                }
            }
    }

    func stop() {
        isRunning = false
        timer?.cancel()
        timer = nil
    }

    func reset() {
        stop()
        secondsLeft = 20 * 60
        completed = false
    }
}

// MARK: - Toolkit Section

struct CravingToolkitSection: View {
    @EnvironmentObject var store: FastingStore
    @EnvironmentObject var appState: AppState
    @State private var isExpanded = false
    @State private var activeTool: ToolTab? = nil
    @StateObject private var countdownState = CountdownState()

    enum ToolTab: String, CaseIterable, Identifiable {
        case countdown = "20 Minutes"
        case reframe   = "Quick Reframe"
        case why       = "My Why"
        case log       = "Log It"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed header
            Button {
                withAnimation(.spring(duration: 0.35)) {
                    isExpanded.toggle()
                    if isExpanded && activeTool == nil { activeTool = .countdown }
                }
            } label: {
                HStack {
                    Text("Having a craving?")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color("NCWarning"))

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color("NCWarning"))
                }
                .padding(20)
                .background(Color("NCSurface"))
                .cornerRadius(16, corners: isExpanded ? [.topLeft, .topRight] : .allCorners)
            }

            if isExpanded {
                VStack(spacing: 0) {
                    // Tab strip
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(ToolTab.allCases) { tab in
                                tabChip(tab)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                    }
                    .background(Color("NCSurface").opacity(0.7))

                    Rectangle()
                        .fill(Color("NCTextTertiary").opacity(0.3))
                        .frame(height: 1)

                    // Tool content
                    Group {
                        switch activeTool {
                        case .countdown: CountdownTool(state: countdownState)
                        case .reframe:   ReframeCardTool()
                        case .why:       WhyReminderTool()
                        case .log:       LogCravingTool()
                        case nil:        EmptyView()
                        }
                    }
                    .padding(20)
                    .background(Color("NCSurface"))
                    .cornerRadius(16, corners: [.bottomLeft, .bottomRight])
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .nightcapOpenCravingToolkit)) { _ in
            withAnimation(.spring(duration: 0.35)) {
                isExpanded = true
                activeTool = .countdown
            }
        }
    }

    private func tabChip(_ tab: ToolTab) -> some View {
        let isActive = activeTool == tab
        return Button {
            withAnimation(.spring(duration: 0.25)) { activeTool = tab }
        } label: {
            Text(tab.rawValue)
                .font(.system(size: 13, weight: isActive ? .medium : .regular))
                .foregroundStyle(isActive ? Color("NCBackground") : Color("NCTextSecondary"))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isActive ? Color("NCAccent") : Color("NCBackground"))
                .cornerRadius(8)
        }
    }
}

// MARK: - Tool 1: 20-Minute Countdown

struct CountdownTool: View {
    @ObservedObject var state: CountdownState

    var body: some View {
        VStack(spacing: 20) {
            if state.completed {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(Color("NCSuccess"))

                    Text("It passed. They always do.")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 8) {
                    Text("Cravings peak and pass in under 20 minutes.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .lineSpacing(3)
                        .multilineTextAlignment(.center)

                    Text("You don't need to resist it — just outlast it.")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .lineSpacing(3)
                        .multilineTextAlignment(.center)
                }

                Text(formattedTime)
                    .font(.system(size: 48, weight: .light).monospacedDigit())
                    .foregroundStyle(state.isRunning ? Color("NCTextPrimary") : Color("NCTextTertiary"))

                Button {
                    if state.isRunning { state.stop() } else { state.start() }
                } label: {
                    Text(state.isRunning ? "Pause" : (state.secondsLeft < 20 * 60 ? "Resume" : "Start the 20 minutes"))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color("NCBackground"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("NCAccent"))
                        .cornerRadius(12)
                }

                if state.secondsLeft < 20 * 60 && !state.isRunning {
                    Button { state.reset() } label: {
                        Text("Reset")
                            .font(.system(size: 13))
                            .foregroundStyle(Color("NCTextSecondary"))
                    }
                }
            }
        }
    }

    private var formattedTime: String {
        String(format: "%d:%02d", state.secondsLeft / 60, state.secondsLeft % 60)
    }
}

// MARK: - Tool 2: Quick Reframe Card

struct ReframeCardTool: View {
    @State private var currentIndex: Int = 0
    @State private var cardText: String = QuoteLibrary.cravingCards[0]
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 20) {
            Text(cardText)
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .padding(.vertical, 24)
                .offset(x: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { dragOffset = $0.translation.width }
                        .onEnded { value in
                            if value.translation.width < -40 {
                                nextCard()
                            }
                            withAnimation { dragOffset = 0 }
                        }
                )

            Text("Swipe left for another")
                .font(.system(size: 11))
                .tracking(1)
                .foregroundStyle(Color("NCTextTertiary"))

            Button {
                nextCard()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .light))
                    Text("Next")
                        .font(.system(size: 14))
                }
                .foregroundStyle(Color("NCTextSecondary"))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color("NCBackground"))
                .cornerRadius(8)
            }
        }
    }

    private func nextCard() {
        let result = QuoteLibrary.randomCravingCard(excluding: currentIndex)
        withAnimation(.spring(duration: 0.25)) {
            currentIndex = result.index
            cardText = result.text
        }
    }
}

// MARK: - Tool 3: Why Reminder

struct WhyReminderTool: View {
    @EnvironmentObject var appState: AppState

    private var statement: String {
        switch appState.userGoal {
        case .sleepBetter:   return "I'm doing this because I want to wake up rested."
        case .moreEnergy:    return "I'm doing this because I want real energy — not borrowed energy."
        case .breakCravings: return "I'm doing this because the craving cycle ends here."
        case .loseWeight:    return "I'm doing this because my body deserves a clean fuel."
        case .curious:       return "I'm doing this to find out what my baseline actually feels like."
        case nil:            return "I'm doing this because something needs to change."
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(statement)
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .padding(.vertical, 20)

            if let goal = appState.userGoal {
                Text(goal.affirmation)
                    .font(.system(size: 13))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

// MARK: - Tool 4: Log Craving

struct LogCravingTool: View {
    @EnvironmentObject var store: FastingStore
    @State private var selectedTrigger: CravingTrigger? = nil
    @State private var logged = false

    var body: some View {
        VStack(spacing: 20) {
            if logged, let trigger = selectedTrigger {
                VStack(spacing: 12) {
                    Text("Noted.")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))

                    Text("Knowing the trigger is half of beating it.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color("NCTextSecondary"))

                    Text(trigger.insight)
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .lineSpacing(4)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)

                    Button {
                        selectedTrigger = nil
                        logged = false
                    } label: {
                        Text("Log another")
                            .font(.system(size: 13))
                            .foregroundStyle(Color("NCTextTertiary"))
                            .padding(.top, 8)
                    }
                }
                .transition(.opacity)
            } else {
                VStack(spacing: 12) {
                    Text("What's triggering this?")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color("NCTextSecondary"))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(CravingTrigger.allCases) { trigger in
                            triggerChip(trigger)
                        }
                    }
                }
            }
        }
    }

    private func triggerChip(_ trigger: CravingTrigger) -> some View {
        let isSelected = selectedTrigger == trigger
        return Button {
            withAnimation(.spring(duration: 0.25)) {
                selectedTrigger = trigger
                store.logCraving(trigger)
                logged = true
            }
        } label: {
            Text(trigger.rawValue)
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? Color("NCBackground") : Color("NCTextPrimary"))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color("NCAccent") : Color("NCBackground"))
                .cornerRadius(8)
        }
    }
}

// MARK: - Corner radius helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
