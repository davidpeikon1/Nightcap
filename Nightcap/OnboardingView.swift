import SwiftUI

// MARK: - Root Onboarding Container

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var fastingStore: FastingStore
    @State private var showGoalSheet = false

    var body: some View {
        ZStack {
            Color("NCBackground").ignoresSafeArea()

            switch appState.onboardingStep {
            case .hook:
                HookScreen()
                    .transition(.opacity)
            case .timerCoachmark, .quoteCoachmark:
                HomeWithCoachmark()
                    .transition(.opacity)
            case .goalSetting:
                // Home stays visible behind the sheet for continuity
                HomeView(coachmarkMode: true)
                    .transition(.opacity)
            case .notifications:
                NotificationPermissionScreen()
                    .transition(.opacity)
            case .firstMilestone:
                FirstMilestoneScreen()
                    .transition(.opacity)
            case .complete:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.onboardingStep)
        .onChange(of: appState.onboardingStep) { _, step in
            showGoalSheet = (step == .goalSetting)
        }
        .sheet(isPresented: $showGoalSheet) {
            GoalSheet()
                .interactiveDismissDisabled()
        }
    }
}

// MARK: - Screen 1: Hook

struct HookScreen: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var fastingStore: FastingStore

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 48) {
                Text("When did you last have\nprocessed sugar?")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Color("NCTextPrimary"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    hookButton("Today") {
                        fastingStore.setInitialDate(at: Calendar.current.startOfDay(for: Date()))
                        appState.advance(to: .timerCoachmark)
                    }
                    hookButton("Yesterday") {
                        let d = Calendar.current.date(byAdding: .day, value: -1,
                                                      to: Calendar.current.startOfDay(for: Date()))!
                        fastingStore.setInitialDate(at: d)
                        appState.advance(to: .timerCoachmark)
                    }
                    hookButton("A few days ago") {
                        let d = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
                        fastingStore.setInitialDate(at: d)
                        appState.advance(to: .timerCoachmark)
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
    }

    private func hookButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color("NCTextPrimary"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color("NCSurface"))
                .cornerRadius(12)
        }
    }
}

// MARK: - Screens 2–3: Home + Coachmarks

struct HomeWithCoachmark: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        ZStack(alignment: .top) {
            HomeView(coachmarkMode: true)

            // Scrim
            Color("NCTextPrimary")
                .opacity(0.45)
                .ignoresSafeArea()
                .onTapGesture { handleTap() }

            if appState.onboardingStep == .timerCoachmark {
                CoachmarkBubble(
                    text: "Your sugar fast started the moment you answered. This is your clock.",
                    arrowUp: true
                )
                .padding(.top, 205)
                .padding(.horizontal, 24)
                .onTapGesture { handleTap() }
                .transition(.scale(scale: 0.9).combined(with: .opacity))

            } else if appState.onboardingStep == .quoteCoachmark {
                CoachmarkBubble(
                    text: "Every day, a new insight about what processed sugar is actually doing — and what life looks like without it.",
                    arrowUp: false
                )
                .padding(.top, 430)
                .padding(.horizontal, 24)
                .onTapGesture { appState.advance(to: .goalSetting) }
                .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.3), value: appState.onboardingStep)
    }

    private func handleTap() {
        if appState.onboardingStep == .timerCoachmark {
            appState.advance(to: .quoteCoachmark)
        }
    }
}

// MARK: - Coachmark Bubble

struct CoachmarkBubble: View {
    let text: String
    let arrowUp: Bool

    var body: some View {
        VStack(spacing: 0) {
            if arrowUp { arrowShape.padding(.leading, 40) }
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color("NCTextPrimary"))
                .lineSpacing(5)
                .padding(20)
                .background(Color("NCBackground"))
                .cornerRadius(16)
            if !arrowUp { arrowShape.rotationEffect(.degrees(180)).padding(.leading, 40) }
        }
    }

    private var arrowShape: some View {
        Triangle()
            .fill(Color("NCBackground"))
            .frame(width: 20, height: 12)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

// MARK: - Screen 4: Goal Setting Sheet

struct GoalSheet: View {
    @EnvironmentObject var appState: AppState
    @State private var selected: UserGoal? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                Color("NCBackground").ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What would you most\nlike to change?")
                                .font(.system(size: 26, weight: .light))
                                .foregroundStyle(Color("NCTextPrimary"))
                                .lineSpacing(4)
                            Text("This personalizes the context throughout the app.")
                                .font(.system(size: 14))
                                .foregroundStyle(Color("NCTextSecondary"))
                        }

                        VStack(spacing: 10) {
                            ForEach(UserGoal.allCases) { goal in
                                goalPill(goal)
                            }
                        }

                        if let g = selected {
                            Text(g.affirmation)
                                .font(.system(size: 14, weight: .light))
                                .foregroundStyle(Color("NCTextSecondary"))
                                .lineSpacing(4)
                                .padding(16)
                                .background(Color("NCSurface"))
                                .cornerRadius(12)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }

                        Button {
                            if let g = selected { appState.setGoal(g) }
                            appState.advance(to: .notifications)
                        } label: {
                            Text("Continue")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(Color("NCBackground"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(selected == nil ? Color("NCTextTertiary") : Color("NCAccent"))
                                .cornerRadius(12)
                        }
                        .disabled(selected == nil)
                        .animation(.easeInOut(duration: 0.2), value: selected)
                    }
                    .padding(24)
                }
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .animation(.spring(duration: 0.3), value: selected)
    }

    private func goalPill(_ goal: UserGoal) -> some View {
        let isSelected = selected == goal
        return Button {
            withAnimation(.spring(duration: 0.25)) { selected = goal }
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

// MARK: - Screen 5: Notification Permission

struct NotificationPermissionScreen: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 32) {
                Image(systemName: "moon")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(Color("NCTextSecondary"))

                VStack(spacing: 14) {
                    Text("The hardest moments\nhappen at 9pm.")
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("Let Nightcap check in with you at the times cravings are most likely. You can change this anytime.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 12)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            VStack(spacing: 16) {
                Button {
                    NotificationManager.shared.requestPermission { _ in
                        appState.advance(to: .firstMilestone)
                    }
                } label: {
                    Text("Turn on reminders")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color("NCBackground"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color("NCAccent"))
                        .cornerRadius(12)
                }

                Button { appState.advance(to: .firstMilestone) } label: {
                    Text("Not now")
                        .font(.system(size: 15))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .padding(.vertical, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Screen 6: First Milestone

struct FirstMilestoneScreen: View {
    @EnvironmentObject var appState: AppState

    private let rows: [(symbol: String, text: String)] = [
        ("clock",  "Your fast timer runs in the background"),
        ("book",   "A new reframe drops every morning"),
        ("bell",   "We'll nudge you at the moments that matter"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 40) {
                Text("Here's what happens next.")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Color("NCTextPrimary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 20) {
                    ForEach(rows, id: \.text) { row in
                        HStack(spacing: 20) {
                            Image(systemName: row.symbol)
                                .font(.system(size: 22, weight: .light))
                                .foregroundStyle(Color("NCTextSecondary"))
                                .frame(width: 32)
                            Text(row.text)
                                .font(.system(size: 16))
                                .foregroundStyle(Color("NCTextPrimary"))
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            Spacer()
            Button {
                withAnimation { appState.advance(to: .complete) }
            } label: {
                Text("Let's go")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color("NCBackground"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color("NCAccent"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }
}
