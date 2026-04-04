import Foundation
import Combine

// MARK: - Onboarding Step

enum OnboardingStep: Int {
    case hook               = 0
    case timerCoachmark     = 1
    case quoteCoachmark     = 2
    case goalSetting        = 3
    case notifications      = 4
    case firstMilestone     = 5
    case complete           = 6
}

// MARK: - User Goal

enum UserGoal: String, CaseIterable, Identifiable {
    case sleepBetter   = "Sleep better"
    case moreEnergy    = "More energy in the mornings"
    case breakCravings = "Break the craving cycle"
    case loseWeight    = "Lose weight"
    case curious       = "Just curious"

    var id: String { rawValue }

    /// First-person commitment label used as the GoalSheet CTA button.
    /// Phrased as a declaration so tapping it feels like a commitment, not a menu item.
    var commitmentLabel: String {
        switch self {
        case .sleepBetter:   return "I'm doing this for my sleep."
        case .moreEnergy:    return "I'm doing this for real energy."
        case .breakCravings: return "I'm ending the craving cycle."
        case .loseWeight:    return "I'm pulling the right lever."
        case .curious:       return "I want to find out."
        }
    }

    /// Short reminder shown in the ResetModal — ties the user's declared reason
    /// to the biological consequence of resetting. Non-judgmental; informational.
    var resetMomentReminder: String {
        switch self {
        case .sleepBetter:
            return "You started this for better sleep. The 3am waking is blood sugar. Resetting tonight restarts that cycle."
        case .moreEnergy:
            return "You started this for real energy. Resetting resets the borrowed-energy cycle, too."
        case .breakCravings:
            return "You started this to end the craving cycle. This is the cycle asking to continue."
        case .loseWeight:
            return "You started this to lower your insulin. Resetting reactivates the fat-storage mechanism."
        case .curious:
            return "You started this to find out what your body feels like without sugar. The experiment is still running."
        }
    }

    /// Default if-then implementation intention derived from the user's goal.
    /// Used in the craving toolkit's "My Plan" tool when no custom plan is saved.
    var defaultIfThenPlan: String {
        switch self {
        case .sleepBetter:
            return "remind myself the 3am waking is blood sugar — not a real need — and wait 20 minutes."
        case .moreEnergy:
            return "eat something with protein or fat instead and wait 20 minutes for the craving to pass."
        case .breakCravings:
            return "start the 20-minute timer and wait. The craving has a ceiling. I know where the ceiling is."
        case .loseWeight:
            return "drink water and remember: this is the insulin lever. Resetting reactivates fat storage."
        case .curious:
            return "get curious about it instead of acting on it — what does it actually feel like to wait it out?"
        }
    }

    /// Rotates through 3 affirmations by day-of-year so "My Why" feels fresh
    /// across multiple visits without requiring any stored state.
    var affirmation: String {
        let dayIndex = (Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1) - 1
        return affirmations[dayIndex % affirmations.count]
    }

    private var affirmations: [String] {
        switch self {
        case .sleepBetter: return [
            "Sugar spikes your cortisol, keeping you wired at night. Breaking the cycle is the most underrated lever for sleep.",
            "Blood sugar crashes at 2–4am trigger a cortisol response that wakes you. Eliminate the spike, eliminate the crash.",
            "Deep sleep — the restorative kind — is disrupted by glycemic variability. Stable blood sugar is the foundation of real rest.",
        ]
        case .moreEnergy: return [
            "The post-lunch crash isn't tiredness — it's blood sugar correction. Remove the spike, remove the crash.",
            "Real energy doesn't have a crash at the other end. Stable blood glucose is qualitatively different from borrowed energy.",
            "The fatigue you've normalized is partly chemical. It's not your baseline — it's your baseline plus sugar debt.",
        ]
        case .breakCravings: return [
            "Cravings aren't a character flaw. They're a dopamine loop. Loops can be rewritten.",
            "The craving has a 20-minute half-life. Every time you outlast it, the neural path that produced it weakens.",
            "You're not fighting willpower against desire. You're interrupting a conditioned response. Those respond to extinction, not force.",
        ]
        case .loseWeight: return [
            "Processed sugar drives insulin, and insulin drives fat storage. This is the lever.",
            "Visceral fat — the metabolically active kind — responds faster to insulin reduction than any other dietary change.",
            "When insulin falls, fat mobilizes. The mechanism isn't mysterious — you're working with it, not against it.",
        ]
        case .curious: return [
            "Most people have never tracked what their body actually feels like without processed sugar. Baseline data is rare — and often surprising.",
            "The question 'what is my actual baseline?' is one of the most interesting experiments you can run on yourself.",
            "You're running an n=1 trial on your own biology. The data is already coming in.",
        ]
        }
    }
}

// MARK: - AppState

class AppState: ObservableObject {

    @Published var onboardingStep: OnboardingStep
    @Published var userGoal: UserGoal?

    private let defaults = UserDefaults.standard

    init() {
        let raw = defaults.integer(forKey: "onboardingStep")
        self.onboardingStep = OnboardingStep(rawValue: raw) ?? .hook
        if let g = defaults.string(forKey: "userGoal") {
            self.userGoal = UserGoal(rawValue: g)
        }
    }

    func advance(to step: OnboardingStep) {
        onboardingStep = step
        defaults.set(step.rawValue, forKey: "onboardingStep")
    }

    func setGoal(_ goal: UserGoal) {
        userGoal = goal
        defaults.set(goal.rawValue, forKey: "userGoal")
    }

    var isOnboardingComplete: Bool {
        onboardingStep == .complete
    }
}
