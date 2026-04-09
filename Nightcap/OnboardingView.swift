import SwiftUI
import UIKit

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
        .sheet(isPresented: $showGoalSheet, onDismiss: {
            // Safety fallback: if the sheet was dismissed without advancing, advance now
            // so the user is never stranded on a non-interactive coachmark screen.
            if appState.onboardingStep == .goalSetting {
                appState.advance(to: .notifications)
            }
        }) {
            GoalSheet()
                .interactiveDismissDisabled()
        }
    }
}

// MARK: - Screen 1: Hook

struct HookScreen: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var fastingStore: FastingStore
    @State private var showCustomPicker = false
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 48) {
                VStack(spacing: 12) {
                    Text("When did you last have\nprocessed sugar?")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 32)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)

                    Text("Your clock starts from that moment.")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .multilineTextAlignment(.center)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 8)
                }

                VStack(spacing: 12) {
                    hookButton("Today", delay: 0.15) {
                        fastingStore.setInitialDate(at: Calendar.current.startOfDay(for: Date()))
                        appState.advance(to: .timerCoachmark)
                    }
                    hookButton("Yesterday", delay: 0.22) {
                        let d = Calendar.current.date(byAdding: .day, value: -1,
                                                      to: Calendar.current.startOfDay(for: Date()))!
                        fastingStore.setInitialDate(at: d)
                        appState.advance(to: .timerCoachmark)
                    }
                    hookButton("A few days ago", delay: 0.29) {
                        let d = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
                        fastingStore.setInitialDate(at: d)
                        appState.advance(to: .timerCoachmark)
                    }

                    Button {
                        showCustomPicker = true
                    } label: {
                        Text("Pick an exact time")
                            .font(.system(size: 15))
                            .foregroundStyle(Color("NCTextTertiary"))
                            .padding(.top, 4)
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut(duration: 0.4).delay(0.36), value: appeared)
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
        .onAppear {
            if fastingStore.lastSugarDate != nil {
                appState.advance(to: .timerCoachmark)
            } else {
                withAnimation(.easeOut(duration: 0.5)) { appeared = true }
            }
        }
        .sheet(isPresented: $showCustomPicker, onDismiss: {
            if fastingStore.lastSugarDate != nil {
                appState.advance(to: .timerCoachmark)
            }
        }) {
            EditStartTimeSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }

    private func hookButton(_ title: String, delay: Double, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            Text(title)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color("NCTextPrimary"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color("NCSurface"))
                .cornerRadius(12)
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.easeOut(duration: 0.4).delay(delay), value: appeared)
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
                    text: "Every day, a new insight about what processed sugar is actually doing — and what life looks like without it.",
                    arrowUp: true
                )
                .padding(.top, 200)
                .padding(.horizontal, 24)
                .onTapGesture { handleTap() }
                .transition(.scale(scale: 0.9).combined(with: .opacity))

            } else if appState.onboardingStep == .quoteCoachmark {
                CoachmarkBubble(
                    text: "The timer started the moment you answered. This is your clock.",
                    arrowUp: true
                )
                .padding(.top, 375)
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

// MARK: - Screen 4: Goal Setting Sheet (2 steps: goal → sugar estimate)

struct GoalSheet: View {
    @EnvironmentObject var appState: AppState
    @State private var selected: UserGoal? = nil
    @State private var step = 0   // 0 = goal, 1 = sugar estimation

    var body: some View {
        NavigationStack {
            ZStack {
                Color("NCBackground").ignoresSafeArea()

                if step == 0 {
                    goalStep
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    SugarEstimationStep {
                        appState.advance(to: .notifications)
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
                }
            }
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .animation(.spring(duration: 0.35), value: step)
        .animation(.spring(duration: 0.3), value: selected)
    }

    // MARK: - Step 0: Goal selection

    private var goalStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("What would you most\nlike to change?")
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))
                        .lineSpacing(4)
                    Text("Processed sugar drives different mechanisms for different outcomes. Your goal shapes the science you see.")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .lineSpacing(3)
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
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if let g = selected { appState.setGoal(g) }
                    // Skip sugar step if already set (e.g. from deep link)
                    if appState.dailySugarGrams != nil {
                        appState.advance(to: .notifications)
                    } else {
                        withAnimation(.spring(duration: 0.35)) { step = 1 }
                    }
                } label: {
                    Text(selected?.commitmentLabel ?? "Continue")
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

    private func goalPill(_ goal: UserGoal) -> some View {
        let isSelected = selected == goal
        return Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
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

// MARK: - Sugar Estimation Step

/// Lightweight bucket-picker used during onboarding to capture the user's
/// daily added-sugar estimate. Not a full quiz — four broad ranges + a skip.
/// The midpoint of the selected range becomes the stored estimate.
struct SugarEstimationStep: View {
    @EnvironmentObject var appState: AppState
    var onComplete: () -> Void

    @State private var selected: SugarBucket? = nil

    enum SugarBucket: CaseIterable {
        case low, moderate, high, veryHigh

        var label: String {
            switch self {
            case .low:      return "Under 25g"
            case .moderate: return "25–50g"
            case .high:     return "50–100g"
            case .veryHigh: return "Over 100g"
            }
        }

        var sublabel: String {
            switch self {
            case .low:
                return "Minimal sweets, mostly whole foods"
            case .moderate:
                return "Some daily sweets, flavored drinks, or sauces"
            case .high:
                return "Regular sweets, sodas, or processed snacks"
            case .veryHigh:
                return "Daily sweets, multiple sodas, or desserts with most meals"
            }
        }

        /// Midpoint grams stored as the user's estimate.
        var grams: Int {
            switch self {
            case .low:      return 15
            case .moderate: return 35
            case .high:     return 70
            case .veryHigh: return 130
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("How much added sugar\ndo you have per day?")
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))
                        .lineSpacing(4)
                    Text("A rough estimate is enough. This shapes the biological context you see as you go.")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .lineSpacing(3)
                }

                VStack(spacing: 10) {
                    ForEach(SugarBucket.allCases, id: \.label) { bucket in
                        bucketPill(bucket)
                    }
                }

                if let b = selected {
                    tierPreview(for: b)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                VStack(spacing: 12) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        if let b = selected {
                            appState.quizSugarGrams  = b.grams
                            appState.dailySugarGrams = b.grams
                        }
                        onComplete()
                    } label: {
                        Text("Set my number")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color("NCBackground"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(selected == nil ? Color("NCTextTertiary") : Color("NCAccent"))
                            .cornerRadius(12)
                    }
                    .disabled(selected == nil)
                    .animation(.easeInOut(duration: 0.2), value: selected)

                    Button {
                        onComplete()
                    } label: {
                        Text("Skip for now")
                            .font(.system(size: 15))
                            .foregroundStyle(Color("NCTextTertiary"))
                            .padding(.vertical, 8)
                    }
                }
            }
            .padding(24)
        }
        .animation(.spring(duration: 0.3), value: selected)
    }

    private func bucketPill(_ bucket: SugarBucket) -> some View {
        let isSelected = selected == bucket
        return Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            withAnimation(.spring(duration: 0.25)) { selected = bucket }
        } label: {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(bucket.label)
                        .font(.system(size: 15, weight: isSelected ? .medium : .regular))
                        .foregroundStyle(isSelected ? Color("NCBackground") : Color("NCTextPrimary"))
                    Text(bucket.sublabel)
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(isSelected ? Color("NCBackground").opacity(0.75) : Color("NCTextTertiary"))
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color("NCBackground"))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(isSelected ? Color("NCAccent") : Color("NCSurface"))
            .cornerRadius(12)
        }
    }

    private func tierPreview(for bucket: SugarBucket) -> some View {
        let tier = SugarTier(grams: bucket.grams)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle().fill(tier.color).frame(width: 6, height: 6)
                Text(tier.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(tier.color)
            }
            Text(tier.biologicalNote)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(Color("NCSurface"))
        .cornerRadius(12)
    }
}

// MARK: - Screen 5: Notification Permission

struct NotificationPermissionScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var isRequesting = false
    @State private var alreadyDenied = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 32) {
                Image(systemName: "moon")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(Color("NCTextSecondary"))

                VStack(spacing: 14) {
                    Text("The hardest moments\ntend to happen in the evening.")
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text("Evening cravings are when most resets happen. A reminder at the right moment can make the difference.")
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
                if alreadyDenied {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open Settings to enable")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color("NCBackground"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color("NCWarning"))
                            .cornerRadius(12)
                    }
                } else {
                    Button {
                        guard !isRequesting else { return }
                        isRequesting = true
                        NotificationManager.shared.requestPermission { _ in
                            appState.advance(to: .firstMilestone)
                        }
                    } label: {
                        Text("Turn on reminders")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color("NCBackground"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(isRequesting ? Color("NCAccent").opacity(0.6) : Color("NCAccent"))
                            .cornerRadius(12)
                    }
                    .disabled(isRequesting)
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
        .onAppear {
            NotificationManager.shared.checkAuthorizationStatus { status in
                if status == .authorized {
                    // Already authorized — skip straight to next screen.
                    appState.advance(to: .firstMilestone)
                } else if status == .denied {
                    alreadyDenied = true
                }
            }
        }
    }
}

// MARK: - Screen 6: First Milestone

struct FirstMilestoneScreen: View {
    @EnvironmentObject var appState: AppState
    @State private var visibleRows: Int = 0

    private var rows: [(symbol: String, text: String)] {
        var base: [(symbol: String, text: String)] = [
            ("clock",  "Your timer is already running"),
            ("book",   "A new reframe drops every morning"),
            ("bell",   "Reminders fire at your highest-risk moments"),
        ]
        if let g = appState.dailySugarGrams {
            base.append(("chart.bar", "Your number (\(g)g/day) shapes the biology you see"))
        }
        return base
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: 40) {
                VStack(spacing: 8) {
                    Text("You're set.")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Text("Here's what happens next.")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .opacity(visibleRows >= 1 ? 1 : 0)
                }

                VStack(spacing: 20) {
                    ForEach(Array(rows.enumerated()), id: \.element.text) { idx, row in
                        HStack(spacing: 20) {
                            Image(systemName: row.symbol)
                                .font(.system(size: 20, weight: .light))
                                .foregroundStyle(Color("NCSuccess"))
                                .frame(width: 32)
                            Text(row.text)
                                .font(.system(size: 16, weight: .light))
                                .foregroundStyle(Color("NCTextPrimary"))
                            Spacer()
                        }
                        .opacity(visibleRows > idx ? 1 : 0)
                        .offset(y: visibleRows > idx ? 0 : 8)
                        .animation(.easeOut(duration: 0.4).delay(Double(idx) * 0.15), value: visibleRows)
                    }
                }
                .padding(.horizontal, 24)
            }
            Spacer()
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                withAnimation { appState.advance(to: .complete) }
            } label: {
                Text("Start the clock")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color("NCBackground"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color("NCAccent"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
            .opacity(visibleRows >= rows.count ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.55), value: visibleRows)
        }
        .onAppear {
            // Stagger the rows in
            for i in 1...rows.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                    withAnimation { visibleRows = i }
                }
            }
        }
    }
}
