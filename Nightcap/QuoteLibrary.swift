import Foundation

// MARK: - Quote Model

struct ReframeQuote: Identifiable {
    let id = UUID()
    let text: String
    let science: String
    let tier: QuoteTier
}

enum QuoteTier: Int, CaseIterable {
    case zeroToThirtyMin     = 0
    case thirtyMinToTwoHours = 1
    case twoToSixHours       = 2
    case sixTo24Hours        = 3
    case oneToThreeDays      = 4
    case threeToSevenDays    = 5
    case sevenTo14Days       = 6
    case fourteenTo30Days    = 7
    case thirtyPlusDays      = 8

    static func tier(for seconds: TimeInterval) -> QuoteTier {
        switch seconds {
        case ..<1_800:        return .zeroToThirtyMin
        case ..<7_200:        return .thirtyMinToTwoHours
        case ..<21_600:       return .twoToSixHours
        case ..<86_400:       return .sixTo24Hours
        case ..<259_200:      return .oneToThreeDays
        case ..<604_800:      return .threeToSevenDays
        case ..<1_209_600:    return .sevenTo14Days
        case ..<2_592_000:    return .fourteenTo30Days
        default:              return .thirtyPlusDays
        }
    }
}

// MARK: - Quote Library

struct QuoteLibrary {

    // MARK: Full quote content

    static let all: [QuoteTier: [ReframeQuote]] = [

        .zeroToThirtyMin: [
            ReframeQuote(
                text: "Processed sugar activates the same dopamine pathways as alcohol. The craving you feel right now is real — and it will pass within 20 minutes.",
                science: "Fructose triggers a release of dopamine and opioid peptides in the brain's reward center. This is not a character flaw. It's a designed response to a designed substance. The 20-minute window is real — after it closes, the neurochemical pull weakens significantly.",
                tier: .zeroToThirtyMin
            ),
            ReframeQuote(
                text: "Your body didn't fail. It responded exactly as it was designed to. Processed sugar is engineered by food scientists to override your satiety signals.",
                science: "The combination of sugar, fat, and salt used in processed foods is specifically calibrated to hit what researchers call the 'bliss point' — the ratio that maximizes craving and minimizes satisfaction. Your brain was outdesigned. That's not weakness.",
                tier: .zeroToThirtyMin
            ),
            ReframeQuote(
                text: "The moment after a reset is the hardest moment in the cycle. It's also the moment that matters most — because you're still here.",
                science: "Research on habit loops shows that the period immediately after a relapse is when most people abandon their goal entirely — not because the goal is wrong, but because shame triggers avoidance. Staying engaged after a reset is the most important behavior in long-term change.",
                tier: .zeroToThirtyMin
            ),
        ],

        .thirtyMinToTwoHours: [
            ReframeQuote(
                text: "The dopamine spike has already peaked and is falling. What you feel right now is the system normalizing, not failing.",
                science: "Blood glucose rises rapidly after consuming refined sugar, triggering insulin and a compensatory dopamine response. The crash typically occurs within 45–90 minutes. What feels like craving during this window is your body seeking to re-trigger the spike — not genuine hunger.",
                tier: .thirtyMinToTwoHours
            ),
            ReframeQuote(
                text: "Processed sugar is the only food substance where the more you eat, the more the food industry profits — and the more you need to feel satisfied.",
                science: "Tolerance to sugar's dopamine effect develops with repeated exposure, similar to tolerance in alcohol and drug use. This means more is required over time to produce the same pleasurable response — a textbook feature of addictive substances.",
                tier: .thirtyMinToTwoHours
            ),
            ReframeQuote(
                text: "An hour ago you made a choice. Your body is already responding to it. The response isn't dramatic — but it's happening.",
                science: "Insulin levels begin normalizing within 1–2 hours after the last glucose exposure. The liver, which bears the primary burden of processing fructose, begins reducing its metabolic load. These are quiet changes. They're still real.",
                tier: .thirtyMinToTwoHours
            ),
        ],

        .twoToSixHours: [
            ReframeQuote(
                text: "Insulin is falling. The fog you feel — if you feel it — is chemical, not personal.",
                science: "Post-sugar cognitive fog is caused by reactive hypoglycemia: insulin overshoots, blood glucose drops below baseline, and the brain — which runs almost exclusively on glucose — becomes temporarily underperforming. This is not you. It's chemistry.",
                tier: .twoToSixHours
            ),
            ReframeQuote(
                text: "Your gut microbiome starts shifting within hours of removing processed sugar. You have more non-human cells in your body than human ones — and they're already changing.",
                science: "The gut microbiome responds to dietary changes within 24–48 hours. Beneficial bacteria that are suppressed by high sugar environments begin recovering within the first few hours of removal. This is one of the fastest physiological changes the body makes in response to diet.",
                tier: .twoToSixHours
            ),
            ReframeQuote(
                text: "The craving you outlasted an hour ago was a hormone. Not a decision. Not a failure. A hormone.",
                science: "Ghrelin, often called the hunger hormone, spikes in response to habitual eating cues — including time of day and environmental triggers — and drives the sensation of craving independent of actual hunger. Understanding that cravings are hormonal allows you to observe them rather than obey them.",
                tier: .twoToSixHours
            ),
        ],

        .sixTo24Hours: [
            ReframeQuote(
                text: "By now your liver has cleared most of the fructose from your last meal. You're running on a cleaner fuel than you were yesterday.",
                science: "The liver is the primary site of fructose metabolism. Unlike glucose, fructose is processed almost entirely by the liver, where excess fructose is converted to fat. After 6–8 hours without processed sugar, liver glycogen from fructose has largely been cleared, reducing the metabolic burden significantly.",
                tier: .sixTo24Hours
            ),
            ReframeQuote(
                text: "Sleep tonight will be different. Without a blood sugar spike in the evening, cortisol won't spike at 2–4am looking for glucose to stabilize you.",
                science: "Blood sugar crashes during sleep trigger a cortisol response — the body's emergency glucose management system. This is one of the primary causes of unexplained 3am waking. Without the evening sugar spike, the crash doesn't happen, and the cortisol doesn't fire.",
                tier: .sixTo24Hours
            ),
            ReframeQuote(
                text: "Most people have consumed processed sugar again by now. Statistically, you're already in the minority.",
                science: "Research on dietary behavior change shows that the first 6 hours after a decision to change are the highest-risk period for reverting to the baseline behavior. If you're past this window, you've already outlasted the majority of people who make the same decision.",
                tier: .sixTo24Hours
            ),
        ],

        .oneToThreeDays: [
            ReframeQuote(
                text: "Your taste buds turn over every 10–14 days. You're already into the first cycle of what will become a new sense of taste.",
                science: "Taste receptor cells have a lifespan of 10–14 days. Chronic exposure to high-sugar foods suppresses the sensitivity of sweet receptors, requiring higher concentrations to register the same sweetness. Within the first few days of sugar reduction, receptor sensitivity begins recovering — meaning natural foods start tasting sweeter.",
                tier: .oneToThreeDays
            ),
            ReframeQuote(
                text: "The behavioral pattern is starting to shift. The craving still shows up. But it's a reflex now, not a need.",
                science: "Behavioral neuroscience distinguishes between habitual cravings (triggered by environmental cues and timing) and physiological cravings (driven by genuine metabolic need). After 2–3 days without processed sugar, the physiological component has largely resolved. What remains is habit — which responds to a different set of interventions.",
                tier: .oneToThreeDays
            ),
            ReframeQuote(
                text: "Three days is enough to show your body a different pattern. Not to establish it — but to show it.",
                science: "Habit formation research suggests that the first 2–3 days of a behavior change are the period of highest volatility and highest neurological plasticity. The brain is actively deciding whether this is a new pattern or a temporary deviation. Every day in this window counts more than days later in the process.",
                tier: .oneToThreeDays
            ),
        ],

        .threeToSevenDays: [
            ReframeQuote(
                text: "After 72 hours, dopamine receptor sensitivity begins to recover. Foods you've forgotten you enjoyed are about to remind you they exist.",
                science: "Chronic exposure to high-dopamine foods like sugar causes downregulation of D2 dopamine receptors — the brain physically reduces the number of receptors to compensate for overstimulation. After 3–4 days without the stimulus, receptor upregulation begins. This is why people who successfully reduce sugar often describe a new appreciation for simple flavors.",
                tier: .threeToSevenDays
            ),
            ReframeQuote(
                text: "Day 4 is the day most people report their first 'I don't actually want it' moment. Pay attention if it comes.",
                science: "The first spontaneous experience of not wanting something you previously craved represents a real neurochemical shift — the beginning of extinction learning, where previously conditioned stimulus-response connections begin weakening. It is a biological signal, not a coincidence.",
                tier: .threeToSevenDays
            ),
            ReframeQuote(
                text: "The cravings at this stage are mostly habit, not hunger. They know a specific time. A specific place. A specific feeling. They're a reflex — and reflexes can be interrupted.",
                science: "Classical conditioning governs most sugar cravings by day 4–5. The conditioned stimulus (9pm, the couch, the TV) triggers the conditioned response (craving) independent of genuine metabolic need. Breaking the stimulus-response link requires repeated exposure to the cue without the reward — which is exactly what you're doing.",
                tier: .threeToSevenDays
            ),
        ],

        .sevenTo14Days: [
            ReframeQuote(
                text: "A week without processed sugar is long enough to have measurably changed your gut microbiome composition. That's not motivational language. That's biology.",
                science: "A landmark 2014 study published in Nature showed that the gut microbiome can shift composition in as little as 24–48 hours in response to dietary change. After 7 days, changes are significant and measurable. Specifically, Firmicutes (associated with sugar metabolism and fat storage) decrease, while Bacteroidetes (associated with lean metabolic function) increase.",
                tier: .sevenTo14Days
            ),
            ReframeQuote(
                text: "Most people never stay here long enough to find out what their baseline energy actually feels like — energy that isn't borrowed from a sugar spike and repaid in a crash.",
                science: "The energy you feel on a stable blood glucose curve is qualitatively different from the peaks and valleys of a high-sugar diet. It is lower in amplitude but significantly higher in duration and cognitive quality. Most people have never experienced it as adults. What you may be feeling right now is closer to your biological norm than anything you've felt in years.",
                tier: .sevenTo14Days
            ),
            ReframeQuote(
                text: "At this stage, the work is identity. You're not someone who is trying to quit sugar. You're becoming someone who doesn't eat it.",
                science: "Identity-based habit change — extensively documented in behavioral psychology research — is one of the most durable predictors of long-term success. When behavior aligns with self-concept rather than willpower or rules, relapse rates drop significantly. The question changes from 'how do I resist this?' to 'is this who I am?'",
                tier: .sevenTo14Days
            ),
        ],

        .fourteenTo30Days: [
            ReframeQuote(
                text: "Two weeks. Your insulin sensitivity has measurably improved. Your liver has had real recovery time. The downstream effects — energy, skin, sleep — are just beginning.",
                science: "Insulin resistance begins to reverse with as little as 2 weeks of refined sugar reduction. A 2015 study published in Obesity found significant improvements in metabolic markers after just 9 days of sugar reduction, even with calorie intake held constant.",
                tier: .fourteenTo30Days
            ),
            ReframeQuote(
                text: "You're past the point where most people turn back. The terrain ahead is genuinely different from what most people ever experience.",
                science: "Research on dietary behavior change identifies 2 weeks as the critical threshold after which the probability of long-term maintenance rises sharply. Neurological habituation to the absence of the substance strengthens, and the perceived difficulty of maintenance decreases. You are statistically in a different category now.",
                tier: .fourteenTo30Days
            ),
            ReframeQuote(
                text: "At this point, cravings are mostly memory, not biology. The biology has already shifted — what you're navigating now is the echo of the old pattern.",
                science: "By two weeks, physiological sugar dependence has largely resolved. What persists is conditioned craving — stimulus-response associations formed through repeated pairing of cues (stress, time of day, environment) with sugar. These conditioned responses weaken through extinction: repeated exposure to the cue without the reward.",
                tier: .fourteenTo30Days
            ),
            ReframeQuote(
                text: "Your skin, your sleep, your energy — these aren't linear. The improvements compound quietly over weeks. You may be in the middle of one right now.",
                science: "Glycation — the binding of sugar molecules to collagen and elastin — reverses slowly but measurably after sustained sugar reduction. At two weeks, AGE (advanced glycation end-product) formation has significantly slowed. Sleep architecture improvements, driven by stable nocturnal blood glucose, are often fully consolidated by week 2–3.",
                tier: .fourteenTo30Days
            ),
        ],

        .thirtyPlusDays: [
            ReframeQuote(
                text: "A month. Your dopamine system has had meaningful time to recover. The baseline you feel now is closer to your actual, unmodified biology than anything you've felt in years.",
                science: "D2 receptor density, which downregulates with chronic dopaminergic overstimulation, requires approximately 4 weeks to show significant recovery. At 30 days, neuroimaging studies show measurable changes in the brain's reward circuitry — changes that make the natural world more rewarding and the craving for extreme stimuli less urgent.",
                tier: .thirtyPlusDays
            ),
            ReframeQuote(
                text: "You're not trying to quit sugar anymore. That's not what this is. You've already quit. What you're doing now is living differently.",
                science: "The neuroscience of identity consolidation shows that after sustained behavior change, the brain begins encoding the new behavior as default rather than effortful. The neural pathway for the old habit weakens through disuse; the new pattern strengthens through repetition. This is no longer a decision you're making. It's becoming who you are.",
                tier: .thirtyPlusDays
            ),
            ReframeQuote(
                text: "People around you have probably noticed something. They might not know what. You do.",
                science: "The visible effects of sustained sugar elimination — reduced inflammation markers, improved skin clarity, more stable mood, sharper cognition — are often noticed by others before the person themselves can see them clearly. Changes that compound over 30 days are significant enough to be externally observable.",
                tier: .thirtyPlusDays
            ),
            ReframeQuote(
                text: "This far in, the occasional offer of something sweet at a social event doesn't feel like restraint. It feels like preference. That's the shift.",
                science: "Identity-based preference change — the point at which behavior aligns with self-concept rather than willpower — is the most durable form of habit maintenance. When the question becomes 'this isn't for me' rather than 'I'm trying not to', relapse probability drops significantly. Research suggests this shift occurs, on average, somewhere between weeks 3 and 6.",
                tier: .thirtyPlusDays
            ),
        ],
    ]

    // MARK: Craving-moment cards (for the toolkit)

    static let cravingCards: [String] = [
        "What you're feeling is 5–10 grams of dopamine chemistry. It will metabolize.",
        "This exact feeling has a 20-minute half-life. It cannot sustain itself.",
        "The food you're craving was designed in a lab to make you feel exactly this. That's not hunger.",
        "Your prefrontal cortex is temporarily losing to your limbic system. It wins when you wait.",
        "In 3 hours you'll be grateful you didn't.",
        "The craving is loudest right before it disappears.",
        "This feeling is a wave. It has a peak. You're probably near it.",
        "You're not fighting the food. You're outlasting a hormone.",
        "The 20-minute rule: if you still want it in 20 minutes, it's hunger. If it passed, it was chemistry.",
        "Every craving you outlast weakens the neural path that produced it.",
    ]

    // MARK: Selection

    /// Returns the deterministic daily quote for the given elapsed seconds.
    /// Uses day-of-year for daily rotation within the tier, keeping it consistent across resets.
    static func dailyQuote(for elapsedSeconds: TimeInterval, on date: Date = Date()) -> ReframeQuote {
        let tier = QuoteTier.tier(for: elapsedSeconds)
        let bucket = all[tier] ?? all[.zeroToThirtyMin]!
        let dayIndex = (Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1) - 1
        return bucket[dayIndex % bucket.count]
    }

    static func randomCravingCard(excluding index: Int? = nil) -> (text: String, index: Int) {
        var idx = Int.random(in: 0..<cravingCards.count)
        if let excluded = index, cravingCards.count > 1 {
            while idx == excluded { idx = Int.random(in: 0..<cravingCards.count) }
        }
        return (cravingCards[idx], idx)
    }
}
