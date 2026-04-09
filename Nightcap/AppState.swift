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
            "Ghrelin, the hunger hormone, fires on a learned schedule. The 3am hunger that used to wake you was a blood sugar response — not a need.",
            "Adenosine, the molecule that builds sleep pressure throughout the day, accumulates cleanly when your metabolic load is low. You're sleeping differently now.",
            "REM sleep — when memories consolidate — extends when the brain isn't managing a nocturnal glucose correction. That's a different kind of rest.",
            "The 90-minute sleep cycle that governs restoration is disrupted by cortisol spikes. Removing the spikes changes the architecture of the night.",
        ]
        case .moreEnergy: return [
            "The post-lunch crash isn't tiredness — it's blood sugar correction. Remove the spike, remove the crash.",
            "Real energy doesn't have a crash at the other end. Stable blood glucose is qualitatively different from borrowed energy.",
            "The fatigue you've normalized is partly chemical. It's not your baseline — it's your baseline plus sugar debt.",
            "Mitochondria — the energy producers in every cell — run more efficiently on fat oxidation than on glucose peaks and corrections. You're fueling differently now.",
            "Cortisol variability throughout the day drops when blood sugar is stable. Steadier energy isn't inspiration — it's a different hormonal environment.",
            "The afternoon crash most people schedule their day around is reactive hypoglycemia. It's not inevitable — it's dietary.",
            "The flat period during the first few days of transition is the system reconfiguring, not your natural state. On the other side is a baseline you haven't measured yet.",
        ]
        case .breakCravings: return [
            "Cravings aren't a character flaw. They're a dopamine loop. Loops can be rewritten.",
            "The craving has a 20-minute half-life. Every time you outlast it, the neural path that produced it weakens.",
            "You're not fighting willpower against desire. You're interrupting a conditioned response. Those respond to extinction, not force.",
            "The mesolimbic dopamine system — the brain's reward center — is already quieter than it was on day one. The signal weakens with each non-reinforced craving.",
            "Conditioned cravings fire because a cue was paired with a reward enough times to become automatic. The pairing breaks through repetition. That's what you're doing.",
            "By three weeks, the extinction of the old craving reflex has been measurable in clinical settings. You're in that window now.",
            "The craving isn't asking for food. It's asking for a dopamine spike. The distinction is the whole game.",
        ]
        case .loseWeight: return [
            "Processed sugar drives insulin, and insulin drives fat storage. This is the lever.",
            "Visceral fat — the metabolically active kind — responds faster to insulin reduction than any other dietary change.",
            "When insulin falls, fat mobilizes. The mechanism isn't mysterious — you're working with it, not against it.",
            "Lipolysis — the breakdown of stored fat for fuel — is suppressed by insulin. Lower insulin means fat can actually move. You've been creating that environment.",
            "The liver's role in fat synthesis is driven by fructose overload. Removing the overload lets the liver shift from fat-building to fat-clearing.",
            "Leptin — the satiety hormone that tells you when you've had enough — works better when insulin is lower. You're rebuilding sensitivity to both signals simultaneously.",
            "Visceral fat isn't just a storage problem — it actively secretes inflammatory signals that make weight loss harder. Reducing it changes the hormonal environment.",
        ]
        case .curious: return [
            "Most people have never tracked what their body actually feels like without processed sugar. Baseline data is rare — and often surprising.",
            "The question 'what is my actual baseline?' is one of the most interesting experiments you can run on yourself.",
            "You're running an n=1 trial on your own biology. The data is already coming in.",
            "The differences you're noticing — in energy, sleep, hunger timing, mood — are biological signals. Most people never collect this data because they never change the variable.",
            "What researchers study in controlled trials, you're running on yourself with direct access to the outcome data. That's a different kind of knowing.",
            "Baseline is a harder question than it sounds. You can't know what your actual baseline is without changing the things that are modifying it. That's what this is.",
            "Every day adds to a picture most people never draw. The longer you run it, the more specific the answer gets.",
        ]
        }
    }
}

// MARK: - AppState

class AppState: ObservableObject {

    @Published var onboardingStep: OnboardingStep
    @Published var userGoal: UserGoal?

    /// The user's estimated daily added-sugar intake in grams.
    /// Seeded from the quiz on first install; updatable at any time.
    @Published var dailySugarGrams: Int? {
        didSet {
            guard let g = dailySugarGrams else { return }
            defaults.set(g, forKey: "dailySugarGrams")
            defaults.set(Date(), forKey: "dailySugarGramsUpdated")
        }
    }

    /// The original estimate from the quiz — preserved so we can show
    /// delta when the user self-reports a lower number over time.
    @Published var quizSugarGrams: Int? {
        didSet {
            guard let g = quizSugarGrams else { return }
            defaults.set(g, forKey: "quizSugarGrams")
        }
    }

    /// The date the user last updated their number (quiz or manual).
    var dailySugarGramsUpdated: Date? {
        defaults.object(forKey: "dailySugarGramsUpdated") as? Date
    }

    private let defaults = UserDefaults.standard

    init() {
        let raw = defaults.integer(forKey: "onboardingStep")
        self.onboardingStep = OnboardingStep(rawValue: raw) ?? .hook
        if let g = defaults.string(forKey: "userGoal") {
            self.userGoal = UserGoal(rawValue: g)
        }
        self.dailySugarGrams = defaults.object(forKey: "dailySugarGrams") as? Int
        self.quizSugarGrams  = defaults.object(forKey: "quizSugarGrams") as? Int
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
