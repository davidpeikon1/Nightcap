import Foundation

struct ContextualCopy {

    static func line(for elapsedSeconds: TimeInterval, on date: Date = Date()) -> String {
        let tier = QuoteTier.tier(for: elapsedSeconds)
        let bucket = lines[tier] ?? lines[.zeroToThirtyMin]!
        // Rotate once per hour so the copy stays stable while the user watches the timer.
        let hour = Calendar.current.component(.hour, from: date)
        return bucket[hour % bucket.count]
    }

    static let lines: [QuoteTier: [String]] = [

        .zeroToThirtyMin: [
            "The craving window is open. It will close.",
            "Your body is still metabolizing the last hit. Give it 20 minutes.",
            "This is the hardest window. You're already through part of it.",
        ],

        .thirtyMinToTwoHours: [
            "The dopamine spike has passed. The craving is losing its grip.",
            "Blood sugar is starting to fall back toward baseline.",
            "Processed sugar is engineered to make this moment hard. You're still here.",
        ],

        .twoToSixHours: [
            "Insulin is falling. The fog is chemical, not personal.",
            "Your gut microbiome starts shifting within hours of removing processed sugar.",
            "The craving you had an hour ago was a hormone, not a choice.",
        ],

        .sixTo24Hours: [
            "By now your liver has cleared most of the fructose. You're running cleaner.",
            "Sleep tonight will be different. Your cortisol won't spike at 3am looking for glucose.",
            "Most people have consumed sugar again by now. You haven't.",
        ],

        .oneToThreeDays: [
            "Your taste buds have a half-life of 10 days. The reset has started.",
            "Three days in, the behavioral pattern begins to shift.",
            "The craving still shows up. But it's quieter than it was yesterday.",
        ],

        .threeToSevenDays: [
            "After 72 hours, dopamine receptor sensitivity begins to recover.",
            "You're in the window where most people report their first 'I don't actually want it' moment.",
            "The cravings at day 4 are mostly habit, not hunger.",
        ],

        .sevenTo14Days: [
            "A week without processed sugar has measurably changed your gut microbiome. That's biology, not motivation.",
            "Most people never stay here long enough to find out what their baseline energy actually feels like.",
            "At this stage the work is identity, not willpower.",
        ],

        .fourteenTo30Days: [
            "Two weeks. Your liver has recalibrated. Your insulin sensitivity has improved. Something real has changed.",
            "You're past the point where most people turn back. This is the territory where it becomes a different kind of life.",
            "At this stage, cravings are mostly memory, not biology. The biology has already shifted.",
            "Most people never find out what their body actually feels like without chronic sugar. You're finding out.",
        ],

        .thirtyPlusDays: [
            "A month. Your dopamine system has had time to genuinely recover. What you feel right now is closer to your actual baseline than anything you've felt in years.",
            "You're not trying to quit sugar anymore. You don't eat it.",
            "The neural pathway for the old habit has weakened through disuse. It doesn't disappear — it just loses priority.",
            "This is identity now, not discipline. The hardest work happened weeks ago.",
        ],
    ]
}
