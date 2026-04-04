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
            ReframeQuote(
                text: "The craving is at peak intensity right now. In 15 minutes, the neurochemistry will be different. That's not optimism — it's the documented pattern.",
                science: "Craving intensity follows a predictable bell curve: it rises to a peak, then falls, regardless of whether the craving is acted on. Studies tracking subjective craving intensity show that the decline begins within 10–15 minutes without any behavioral intervention. Outlasting the peak is the entire game.",
                tier: .zeroToThirtyMin
            ),
            ReframeQuote(
                text: "The decision to open this app was made by the part of your brain that wants to change. That part got you here. That's not nothing.",
                science: "Executive function — the prefrontal cortex's capacity for goal-directed behavior — is measurably impaired by acute sugar cravings through competing dopaminergic signals. Actively seeking behavioral support rather than immediately acting on a craving represents the prefrontal cortex winning a contest against the limbic system.",
                tier: .zeroToThirtyMin
            ),
            ReframeQuote(
                text: "The food you're thinking about right now contains 0 nutrients your body actually needs. What your body needs is on the other side of 20 minutes.",
                science: "Processed sugar provides energy but no essential micronutrients, fiber, or macronutrients that support biological function. The craving is for dopamine, not nutrition. Separating the chemical drive from the biological narrative is one of the most useful cognitive reframes in early habit change.",
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
            ReframeQuote(
                text: "The evening sugar habit exists because your brain associated that time with the reward. The time is real. The need is not.",
                science: "Circadian rhythm research shows that appetite-regulating hormones like ghrelin have daily patterns shaped by habitual meal timing. The body begins preparing for expected rewards before they arrive. Disrupting the timing disrupts the preparation — and over repeated cycles, the association weakens.",
                tier: .thirtyMinToTwoHours
            ),
            ReframeQuote(
                text: "Every hour without it, the reward prediction your brain built around sugar gets slightly weaker. You're training the system.",
                science: "Reward prediction error (RPE) is the gap between an expected dopamine signal and the one that actually arrives. When an expected reward doesn't appear, the brain revises its prediction downward. Each non-reinforced craving is extinction learning in action — it permanently recalibrates the expected reward.",
                tier: .thirtyMinToTwoHours
            ),
            ReframeQuote(
                text: "Right now your body is doing what it's supposed to do after you remove an addictive substance. The discomfort is the adjustment, not the failure.",
                science: "Withdrawal from substances that activate dopamine reward pathways — including processed sugar — follows a predictable trajectory: discomfort peaks early and resolves with continued abstinence. It is the biological cost of recalibration. It is finite, and it ends.",
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
            ReframeQuote(
                text: "The energy dip you might feel right now is your metabolism recalibrating after running on peak-and-crash fuel. Stable energy is on the other side of this.",
                science: "After sustained high-sugar dietary patterns, the body's energy systems have calibrated to expect frequent glucose inputs. Their absence creates a temporary energy trough while the system recalibrates toward fat oxidation and stable blood glucose. This is a normal, temporary adjustment that resolves within the first few days.",
                tier: .twoToSixHours
            ),
            ReframeQuote(
                text: "You've passed the daily window when most people consume sugar. The industry's model requires daily use. You've already broken the daily pattern.",
                science: "Habitual daily intake creates cue-response associations reinforced by circadian hormonal patterns. Passing the daily window without reinforcing the behavior begins disrupting these associations from day one. The disruption compounds with each passing day.",
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
                text: "Most people have consumed processed sugar again by now. By this point, you're already in the minority.",
                science: "Research on dietary behavior change shows that the first 6 hours after a decision to change are the highest-risk period for reverting to the baseline behavior. If you're past this window, you've already outlasted the majority of people who make the same decision.",
                tier: .sixTo24Hours
            ),
            ReframeQuote(
                text: "More than half a day. Every minute now is compound interest on a decision you already made.",
                science: "The physiological difficulty of sugar elimination is strongly front-loaded: the hardest moments cluster in the first 4–6 hours. After this point, moment-to-moment difficulty drops while metabolic and neurochemical benefits begin accumulating. You have crossed the inflection point.",
                tier: .sixTo24Hours
            ),
            ReframeQuote(
                text: "The hardest part of the first day is behind you. What's ahead tonight is ordinary — not the craving window you already survived.",
                science: "Sugar cravings follow a circadian pattern that peaks in the late morning and early evening — correlated with cortisol and ghrelin cycles. After clearing the first evening window, the physiological pressure drops. The rest of the night is biologically quieter.",
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
            ReframeQuote(
                text: "Day 2 is where most people convince themselves they don't really need to do this. If that thought appeared today — that's exactly when you're most right to stay.",
                science: "Behavior change research identifies day 2 as the second-highest risk point for abandonment. Motivation has begun to decline while physiological discomfort has not yet fully resolved. Recognizing this as a predictable phase — not a signal — is the difference between stopping and continuing.",
                tier: .oneToThreeDays
            ),
            ReframeQuote(
                text: "By day 2–3, the dopamine pull is still strong — but it's measurably weaker than day 1. The direction matters as much as the destination.",
                science: "Dopamine D2 receptor rebound begins within 24–72 hours of removing the overstimulating substance. The restoration isn't complete — but the trajectory toward baseline has started. In recovery research, the direction of change is a meaningful clinical indicator independent of how far the trajectory has traveled.",
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
            ReframeQuote(
                text: "The valley of withdrawal is behind you. What's ahead is conditioned craving — triggered by time and place, not biology. Different mechanism. Different tools.",
                science: "The neurological challenge in sugar elimination transitions from acute withdrawal (days 1–3) to conditioned craving (days 3–14). Conditioned cravings respond to behavioral substitution, environmental modification, and extinction learning — not willpower. You are past the hardest version of this.",
                tier: .threeToSevenDays
            ),
            ReframeQuote(
                text: "A week ago you made a decision. You've now carried it through multiple high-risk moments. That's consolidation — the brain is storing it differently than a single choice.",
                science: "Memory consolidation research distinguishes between episodic memory (a single event) and procedural learning (repeated behavioral patterns). Maintaining a behavior change through multiple contextual variations encodes it as procedural rather than episodic. The neural pathway is meaningfully different after a week.",
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
                text: "At this stage, the work is identity, not willpower. The question shifts from 'how do I resist this?' to 'is this who I am?'",
                science: "Identity-based habit change — extensively documented in behavioral psychology research — is one of the most durable predictors of long-term success. When behavior aligns with self-concept rather than willpower or rules, relapse rates drop significantly. The question changes from 'how do I resist this?' to 'is this who I am?'",
                tier: .sevenTo14Days
            ),
            ReframeQuote(
                text: "Your energy and hunger are more predictable than they were a week ago. That's blood sugar stability — and most people have never experienced what you're currently experiencing.",
                science: "Glycemic variability — the amplitude of blood glucose fluctuations over a day — drives fatigue, mood instability, and cognitive fog. After 7–10 days of sugar reduction, glycemic variability drops substantially, producing a qualitatively different energy experience. Most people have not felt this since childhood.",
                tier: .sevenTo14Days
            ),
            ReframeQuote(
                text: "At this stage, the decision isn't happening at the moment of craving. It already happened — days ago. You're living inside a decision, not making one.",
                science: "Behavioral consolidation research distinguishes between situational decision-making and implementation of a prior commitment. After the first 7–10 days, people who maintain a behavior change have shifted from making the decision moment-to-moment to executing one already made. This structural shift is what makes the behavior durable.",
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
            ReframeQuote(
                text: "Cognition runs on stable fuel. By now you've had two weeks without the blood sugar spikes that impair working memory and focus. That clarity you may be noticing is real.",
                science: "Postprandial hyperglycemia — blood sugar spikes after high-sugar meals — is directly associated with reduced performance on working memory and executive function tests. Studies using continuous glucose monitoring show that individuals with flatter glucose curves perform measurably better on cognitive tasks. Two weeks of reduced glycemic variability produces observable cognitive differences.",
                tier: .fourteenTo30Days
            ),
            ReframeQuote(
                text: "Visceral fat — the metabolically active fat around organs — responds faster to dietary change than subcutaneous fat. By now, the process has been underway for weeks.",
                science: "Visceral adipose tissue is highly sensitive to insulin levels. When fasting insulin falls — as it does with sustained sugar reduction — visceral fat mobilizes preferentially. Research shows measurable reductions in visceral fat within 2–4 weeks of significant sugar restriction, even without changes in total caloric intake.",
                tier: .fourteenTo30Days
            ),
            ReframeQuote(
                text: "The research on longevity consistently points to one metabolic marker above others: fasting insulin. Two weeks of sugar reduction has moved yours in the right direction.",
                science: "Chronically elevated insulin — driven primarily by refined carbohydrate and sugar consumption — is independently associated with accelerated cellular aging, increased cancer risk, and cardiovascular disease. Fasting insulin responds rapidly to dietary change: significant improvements are typically measurable within 2–3 weeks of sugar reduction.",
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
                text: "You're not trying to quit sugar anymore. You've already quit. What you're doing now is just living.",
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
            ReframeQuote(
                text: "Food tastes different now. Not because your taste buds are telling you stories — because the receptor sensitivity that was suppressed by chronic sugar exposure has recovered.",
                science: "Chronic high-sugar intake downregulates sweet taste receptors in the mouth, requiring progressively higher concentrations to register the same sweetness. After 30 days, receptor sensitivity recovers significantly — making naturally sweet foods like fruit taste as sweet as processed food once did. This is a genuine perceptual shift, not a placebo.",
                tier: .thirtyPlusDays
            ),
            ReframeQuote(
                text: "The compound interest of consistency is invisible until it isn't. Thirty days of quiet work has changed your gut, your insulin response, your taste, your sleep, your brain. It's in the ledger.",
                science: "Each of the biological changes driven by sugar elimination — microbiome shifts, insulin sensitivity, dopamine receptor recovery, taste receptor normalization, sleep architecture improvements — compounds on the others. They reinforce each other, and they accumulate. At 30 days, the sum of these changes is significantly larger than any individual component.",
                tier: .thirtyPlusDays
            ),
            ReframeQuote(
                text: "Systemic inflammation — the slow background process linked to nearly every chronic disease — requires sustained dietary change to reverse. You've given it a month.",
                science: "C-reactive protein (CRP), interleukin-6 (IL-6), and other inflammatory biomarkers are directly elevated by chronic sugar and refined carbohydrate intake. Sustained reduction produces measurable decreases in these markers, typically becoming statistically significant at 4–6 weeks. Inflammation is silent but expensive. You've been paying down the debt for a month.",
                tier: .thirtyPlusDays
            ),
        ],
    ]

    // MARK: Craving-moment cards (for the toolkit)

    static let cravingCards: [String] = [
        "What you're feeling is a measurable neurochemical event. It will metabolize.",
        "This exact feeling has a 20-minute half-life. It cannot sustain itself.",
        "The food you're craving was designed in a lab to make you feel exactly this. That's not hunger.",
        "Your prefrontal cortex is temporarily losing to your limbic system. It wins when you wait.",
        "In 3 hours you'll be grateful you didn't.",
        "This feeling is a wave. It has a peak. You're probably near it.",
        "You're not fighting the food. You're outlasting a hormone.",
        "The 20-minute rule: if you still want it in 20 minutes, it's hunger. If it passed, it was chemistry.",
        "Every craving you outlast weakens the neural path that produced it.",
        "The craving is loudest in the final minutes before it breaks. That's what loud means right now.",
        // Behavioral
        "Drink a full glass of cold water right now. Thirst and hunger use the same signal.",
        "Step outside for 60 seconds. Cravings are partly spatial — change the room, change the signal.",
        "Eat something with fat or protein. A small piece of cheese. A handful of nuts. Fat satisfies; sugar restarts the cycle.",
        "Change rooms. The craving is partly a conditioned response to the cue in front of you.",
        // Time-reframe
        "Name a specific time 20 minutes from now. That's when this ends.",
        "Your track record for outlasting cravings is 100%. This one is no different.",
        // Cognitive
        "The company that made that food paid researchers to make this moment feel urgent. It isn't.",
        "The craving tells you nothing about what your body needs. It tells you everything about what it's been trained to expect.",
        "Dopamine is chasing the anticipation, not the food itself. Notice what happens to the wanting the moment you eat it.",
        "This is a neural pathway demanding to be used. You don't have to use it.",
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

    // MARK: Day-specific context facts

    /// Returns a single-sentence biological fact anchored to the user's specific day count.
    /// Shown in HeroCard for days 2+ as a third content signal distinct from the quote and
    /// contextual copy. Returns nil when no specific fact is defined for that day.
    static func dayContextFact(for day: Int) -> String? {
        switch day {
        case 1:     return "Hour 1–24: insulin is falling and your liver is clearing the last load."
        case 2:     return "The dopamine pull is still strong at day 2. It drops significantly by day 4."
        case 3:     return "72 hours. Dopamine receptor recovery begins here."
        case 4:     return "Day 4 is when most people report their first genuine 'I don't want it' moment."
        case 5:     return "Gut bacteria composition shifts are measurable by now."
        case 6:     return "Cravings at this stage are mostly conditioned reflex. The biology has largely resolved."
        case 7:     return "One week. Your gut microbiome has measurably shifted — Firmicutes down, Bacteroidetes up."
        case 8:     return "Dopamine receptor recovery is underway. The process takes about 28 days total."
        case 9:     return "The brain is beginning to find more reward in ordinary things."
        case 10:    return "Taste receptor recovery is halfway through its 14-day cycle."
        case 11:    return "The conditioned craving response is weakening through repeated non-reinforcement."
        case 12:    return "Fasting insulin is measurably lower today than it was on day 1."
        case 13:    return "Almost two weeks. The threshold where long-term maintenance becomes statistically likely."
        case 14:    return "Two weeks. fMRI studies show reduced reward-center response to sugar images at this mark."
        case 15:    return "Insulin sensitivity has shifted. The metabolic profile is different from day 1."
        case 16:    return "AGE (advanced glycation end-product) formation has significantly slowed."
        case 17:    return "Sleep architecture improvements driven by stable blood glucose are consolidating now."
        case 18:    return "Visceral fat mobilization is underway — it responds faster than subcutaneous fat."
        case 19:    return "The conditioned craving response continues to extinguish with each passing day."
        case 20:    return "Three weeks. The identity shift is beginning — behavior is aligning with self-concept."
        case 21:    return "Three weeks. Research identifies this as when effortful resistance transitions to preference."
        case 22, 23: return "Approaching the 28-day mark for dopamine receptor recovery."
        case 24, 25: return "Four weeks is the threshold for measurable D2 receptor density recovery."
        case 26, 27: return "The brain's reward circuitry has been adapting for nearly a month."
        case 28:    return "28 days. Dopamine receptor density has had meaningful time to recover."
        case 29, 30: return "A month of clean fuel. Systemic inflammation markers are measurably lower for most people."
        case 31...44: return "Over a month. Inflammatory biomarkers like CRP have had time to shift."
        case 45:    return "45 days. Insulin sensitivity improvements are compounding week by week."
        case 46...59: return "Approaching two months. Visceral fat accumulation has been interrupted for over six weeks."
        case 60:    return "Two months. Gut microbiome, dopamine, taste receptors — all measurably transformed."
        case 61...74: return "Past two months. What you feel now is real biology, not borrowed energy."
        case 75:    return "75 days. Dopamine receptor density is meaningfully recovered from chronic sugar suppression."
        case 76...89: return "Approaching three months. Inflammatory markers continue to fall with each passing week."
        case 90:    return "Three months. Insulin, gut bacteria, taste, sleep — the compound effects are significant."
        case 91...99: return "Past three months. The new pattern is the structural default now."
        case 100:   return "100 days. The neural pathway for the old habit has weakened through disuse."
        case 101...149: return "Past 100 days. What began as effort has become identity."
        case 150:   return "Five months. Cardiovascular risk markers have had significant time to improve."
        case 151...179: return "Approaching six months. The compound interest of consistency is becoming visible."
        case 180:   return "Six months. Cardiovascular risk markers have had meaningful time to shift."
        case 181...269: return "Past six months. The biological changes are substantial and durable."
        case 270:   return "Nine months. Glycation damage to collagen and protein has been actively reversing."
        case 271...364: return "Approaching a year. This is who you are now."
        case 365:   return "A year. Taste receptor sensitivity, dopamine recovery, insulin sensitivity — all transformed."
        case let d where d > 365: return "Past a year. This is not a streak. It's biology."
        default:    return nil
        }
    }

    static func randomCravingCard(excluding index: Int? = nil) -> (text: String, index: Int) {
        var idx = Int.random(in: 0..<cravingCards.count)
        if let excluded = index, cravingCards.count > 1 {
            while idx == excluded { idx = Int.random(in: 0..<cravingCards.count) }
        }
        return (cravingCards[idx], idx)
    }
}
