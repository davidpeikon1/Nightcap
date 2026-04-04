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
            "Sleep tonight may be different. Without the glucose swings, your body has less to manage through the night.",
            "Most people have consumed sugar again by now. You haven't.",
        ],

        .oneToThreeDays: [
            "Taste receptors regenerate roughly every two weeks. At this stage, the shift has started.",
            "Three days in. The cravings are starting to feel less automatic.",
            "The craving still shows up. But it's quieter than it was yesterday.",
        ],

        .threeToSevenDays: [
            "After 72 hours, dopamine receptor sensitivity begins to recover.",
            "Around day 4, most people have their first genuine 'I don't actually want it' moment.",
            "By the end of this week, most cravings are habit, not hunger.",
        ],

        .sevenTo14Days: [
            "A week without processed sugar has measurably changed your gut microbiome. That's biology, not motivation.",
            "Most people never stay here long enough to find out what their baseline energy actually feels like.",
            "At this stage the work is identity, not willpower.",
        ],

        .fourteenTo30Days: [
            "Two weeks. Hepatic fat accumulation has slowed. Insulin sensitivity is measurably different for most people at this mark.",
            "Past the point where most people turn back.",
            "At this stage, cravings are mostly memory, not biology. The biology has already shifted.",
            "Most people never find out what their body actually feels like without chronic sugar. You're finding out.",
        ],

        .thirtyPlusDays: [
            "A month. Dopamine receptor sensitivity has had time to begin recovering. The system is different than it was.",
            "You're not trying to quit sugar anymore. You don't eat it.",
            "The neural pathway for the old habit has weakened through disuse. It doesn't disappear — it just loses priority.",
            "This is identity now, not discipline. The hardest work happened weeks ago.",
        ],
    ]
}
