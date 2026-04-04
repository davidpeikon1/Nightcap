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

    var affirmation: String {
        switch self {
        case .sleepBetter:   return "Sugar spikes your cortisol, keeping you wired at night. Breaking the cycle is the most underrated lever for sleep."
        case .moreEnergy:    return "The post-lunch crash isn't tiredness — it's blood sugar correction. Remove the spike, remove the crash."
        case .breakCravings: return "Cravings aren't a character flaw. They're a dopamine loop. Loops can be rewritten."
        case .loseWeight:    return "Processed sugar drives insulin, and insulin drives fat storage. This is the lever."
        case .curious:       return "Curiosity is how change starts. The data will speak for itself."
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
