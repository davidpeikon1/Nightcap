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
        case breathe   = "Breathe"
        case reframe   = "Quick Reframe"
        case why       = "My Why"
        case log       = "Log It"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed header
            Button {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                withAnimation(.spring(duration: 0.35)) {
                    isExpanded.toggle()
                    if isExpanded && activeTool == nil { activeTool = .countdown }
                }
            } label: {
                HStack {
                    Text("Craving toolkit")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color("NCTextSecondary"))

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color("NCTextSecondary"))
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
                        case .breathe:   BreathingTool()
                        case .reframe:   ReframeCardTool()
                        case .why:       WhyReminderTool()
                        case .log:       LogCravingTool(activeTool: $activeTool)
                        case nil:        EmptyView()
                        }
                    }
                    .id(activeTool)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.18), value: activeTool)
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
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
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
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
        .accessibilityHint("Shows the \(tab.rawValue) tool")
    }
}

// MARK: - Tool 1: 20-Minute Countdown

struct CountdownTool: View {
    @ObservedObject var state: CountdownState
    @State private var inlineCardText: String = ""
    @State private var inlineCardIndex: Int = 0
    @State private var showInlineCard: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            if state.completed {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(Color("NCSuccess"))

                    Text("It passed. They always do.")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))
                        .multilineTextAlignment(.center)

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        state.reset()
                        withAnimation { showInlineCard = false }
                    } label: {
                        Text("Start another 20 minutes")
                            .font(.system(size: 13))
                            .foregroundStyle(Color("NCTextTertiary"))
                            .padding(.top, 4)
                    }
                }
                .padding(.vertical, 16)
            } else {
                VStack(spacing: 8) {
                    Text("Cravings peak and pass in under 20 minutes.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .lineSpacing(3)
                        .multilineTextAlignment(.center)

                    Text("Resistance isn't the goal. Outlasting it is.")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .lineSpacing(3)
                        .multilineTextAlignment(.center)
                }

                ZStack {
                    // Background track
                    Circle()
                        .stroke(Color("NCTextTertiary").opacity(0.15), lineWidth: 3)
                        .frame(width: 148, height: 148)

                    // Progress arc — fills as time runs down
                    let progress = 1.0 - Double(state.secondsLeft) / Double(20 * 60)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            state.isRunning ? Color("NCAccent") : Color("NCTextTertiary").opacity(0.35),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 148, height: 148)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: state.secondsLeft)

                    Text(formattedTime)
                        .font(.system(size: 48, weight: .light).monospacedDigit())
                        .foregroundStyle(state.isRunning ? Color("NCTextPrimary") : Color("NCTextTertiary"))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Countdown timer, \(formattedTime) remaining, \(state.isRunning ? "running" : "paused")")

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if state.isRunning {
                        state.stop()
                    } else {
                        state.start()
                        // Surface a craving card 2 seconds after the timer starts
                        // so the user has something to read during the wait.
                        let result = QuoteLibrary.randomCravingCard(excluding: nil)
                        inlineCardText = result.text
                        inlineCardIndex = result.index
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation(.easeInOut(duration: 0.3)) { showInlineCard = true }
                        }
                    }
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

                // Inline craving card — surfaces automatically when countdown starts
                if showInlineCard {
                    VStack(spacing: 8) {
                        Rectangle()
                            .fill(Color("NCTextTertiary").opacity(0.2))
                            .frame(height: 1)

                        Text(inlineCardText)
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Color("NCTextSecondary"))
                            .lineSpacing(4)
                            .multilineTextAlignment(.center)

                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            let result = QuoteLibrary.randomCravingCard(excluding: inlineCardIndex)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                inlineCardText = result.text
                                inlineCardIndex = result.index
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("another")
                                    .font(.system(size: 11))
                                    .tracking(0.5)
                                Image(systemName: "arrow.left")
                                    .font(.system(size: 9, weight: .light))
                            }
                            .foregroundStyle(Color("NCTextTertiary"))
                        }
                    }
                    .transition(.opacity)
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
    @State private var cardText: String = QuoteLibrary.cravingCards.first ?? ""
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
                        .onChanged { dragOffset = min(0, $0.translation.width) }
                        .onEnded { value in
                            if value.translation.width < -40 {
                                nextCard()
                            }
                            withAnimation { dragOffset = 0 }
                        }
                )
                .onAppear {
                    // Gentle nudge after 1.2s to hint the card is swipeable
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation(.easeInOut(duration: 0.35)) { dragOffset = -22 }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            withAnimation(.spring(duration: 0.4)) { dragOffset = 0 }
                        }
                    }
                }

            HStack(spacing: 4) {
                Text("Swipe left for another")
                    .font(.system(size: 11))
                    .tracking(1)
                    .foregroundStyle(Color("NCTextTertiary"))
                Image(systemName: "arrow.left")
                    .font(.system(size: 9, weight: .light))
                    .foregroundStyle(Color("NCTextTertiary"))
            }

            Button {
                nextCard()
            } label: {
                HStack(spacing: 6) {
                    Text("Next")
                        .font(.system(size: 14))
                    Image(systemName: "arrow.left")
                        .font(.system(size: 12, weight: .light))
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
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
    @State private var showGoalPicker = false

    private var statement: String {
        switch appState.userGoal {
        case .sleepBetter:   return "I'm doing this because I want to wake up rested."
        case .moreEnergy:    return "I'm doing this because I want real energy — not borrowed energy."
        case .breakCravings: return "I'm doing this because the craving cycle ends here."
        case .loseWeight:    return "I'm doing this because fat storage is driven by insulin, and insulin is driven by sugar. This is the lever."
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

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showGoalPicker = true
            } label: {
                Text(appState.userGoal == nil ? "Set your reason" : "Change reason")
                    .font(.system(size: 12))
                    .foregroundStyle(Color("NCTextTertiary"))
                    .padding(.top, 4)
            }
        }
        .sheet(isPresented: $showGoalPicker) {
            GoalPickerSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Compact goal picker (reused from onboarding, dismissable)

struct GoalPickerSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color("NCBackground").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                Text("What's your reason?")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(Color("NCTextPrimary"))
                    .padding(.top, 8)

                VStack(spacing: 10) {
                    ForEach(UserGoal.allCases) { goal in
                        goalPill(goal)
                    }
                }

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color("NCBackground"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color("NCAccent"))
                        .cornerRadius(12)
                }
            }
            .padding(24)
        }
    }

    private func goalPill(_ goal: UserGoal) -> some View {
        let isSelected = appState.userGoal == goal
        return Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.spring(duration: 0.2)) {
                appState.setGoal(goal)
            }
        } label: {
            HStack {
                Text(goal.rawValue)
                    .font(.system(size: 15, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? Color("NCBackground") : Color("NCTextPrimary"))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color("NCBackground"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(isSelected ? Color("NCAccent") : Color("NCSurface"))
            .cornerRadius(12)
        }
    }
}

// MARK: - Tool 4: Log Craving

struct LogCravingTool: View {
    @EnvironmentObject var store: FastingStore
    @Binding var activeTool: CravingToolkitSection.ToolTab?
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

                    // For triggers where breathing directly helps, offer a one-tap path.
                    if trigger == .stress || trigger == .boredom {
                        Button {
                            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            withAnimation(.spring(duration: 0.25)) { activeTool = .breathe }
                        } label: {
                            HStack(spacing: 5) {
                                Text("Try box breathing now")
                                    .font(.system(size: 12))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10, weight: .light))
                            }
                            .foregroundStyle(Color("NCSuccess"))
                        }
                        .padding(.top, 6)
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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
        .animation(.easeInOut(duration: 0.22), value: logged)
    }

    private func triggerChip(_ trigger: CravingTrigger) -> some View {
        let isSelected = selectedTrigger == trigger
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

// MARK: - Tool 5: Box Breathing

final class BreathingState: ObservableObject {
    enum Phase: Equatable { case ready, inhale, hold1, exhale, hold2, done }

    @Published var phase: Phase = .ready
    @Published var beat: Int = 4
    @Published var cycles: Int = 0
    @Published var circleScale: CGFloat = 0.55

    private var timer: AnyCancellable?
    private let totalCycles = 4

    var instruction: String {
        switch phase {
        case .ready, .done: return ""
        case .inhale:       return "Breathe in"
        case .hold1, .hold2: return "Hold"
        case .exhale:       return "Breathe out"
        }
    }

    func start() { advance(to: .inhale) }

    func reset() {
        timer?.cancel()
        phase = .ready
        beat  = 4
        cycles = 0
        circleScale = 0.55
    }

    private func advance(to newPhase: Phase) {
        phase = newPhase
        beat = 4
        timer?.cancel()
        // Distinct haptics for each phase so the exercise can be done eyes-closed.
        switch newPhase {
        case .inhale:
            circleScale = 1.0
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .hold1, .hold2:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .exhale:
            circleScale = 0.55
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        default: break
        }
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                if self.beat > 1 {
                    self.beat -= 1
                } else {
                    self.nextPhase()
                }
            }
    }

    private func nextPhase() {
        switch phase {
        case .inhale: advance(to: .hold1)
        case .hold1:  advance(to: .exhale)
        case .exhale: advance(to: .hold2)
        case .hold2:
            cycles += 1
            if cycles >= totalCycles {
                timer?.cancel()
                withAnimation { phase = .done }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } else {
                advance(to: .inhale)
            }
        default: break
        }
    }
}

struct BreathingTool: View {
    @StateObject private var state = BreathingState()

    var body: some View {
        VStack(spacing: 24) {
            if state.phase == .ready {
                readyView
            } else if state.phase == .done {
                doneView
            } else {
                activeView
            }
        }
        .animation(.easeInOut(duration: 0.35), value: state.phase == .ready || state.phase == .done)
    }

    private var readyView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 10) {
                Text("Box breathing resets your nervous system in under 2 minutes.")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)

                Text("4 in · 4 hold · 4 out · 4 hold")
                    .font(.system(size: 11))
                    .tracking(0.5)
                    .foregroundStyle(Color("NCTextTertiary"))
            }

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                state.start()
            } label: {
                Text("Begin")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color("NCBackground"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("NCAccent"))
                    .cornerRadius(12)
            }
        }
    }

    private var doneView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(Color("NCSuccess"))

            Text("Your nervous system has shifted.")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))
                .multilineTextAlignment(.center)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                state.reset()
            } label: {
                Text("Do it again")
                    .font(.system(size: 13))
                    .foregroundStyle(Color("NCTextTertiary"))
                    .padding(.top, 4)
            }
        }
        .padding(.vertical, 16)
    }

    private var activeView: some View {
        VStack(spacing: 20) {
            Text(state.instruction)
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))
                .id(state.instruction)          // cross-fade when text changes
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: state.instruction)

            ZStack {
                // Outer glow ring
                Circle()
                    .fill(Color("NCSuccess").opacity(0.06))
                    .frame(width: 130, height: 130)

                // Breathing circle
                Circle()
                    .fill(Color("NCSuccess").opacity(0.10))
                    .frame(width: 130, height: 130)
                    .scaleEffect(state.circleScale)
                    .animation(.linear(duration: 4), value: state.circleScale)

                Circle()
                    .stroke(Color("NCSuccess").opacity(0.3), lineWidth: 1.5)
                    .frame(width: 130, height: 130)
                    .scaleEffect(state.circleScale)
                    .animation(.linear(duration: 4), value: state.circleScale)

                Text("\(state.beat)")
                    .font(.system(size: 44, weight: .light).monospacedDigit())
                    .foregroundStyle(Color("NCSuccess").opacity(0.85))
            }
            .frame(width: 130, height: 130)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(state.instruction), \(state.beat)")

            // Cycle progress dots — 4 dots for 4 cycles
            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .fill(i < state.cycles ? Color("NCSuccess") : Color("NCTextTertiary").opacity(0.25))
                        .frame(width: 7, height: 7)
                        .animation(.easeInOut(duration: 0.3), value: state.cycles)
                }
            }
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
