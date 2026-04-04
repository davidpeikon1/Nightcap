import Foundation

struct ContextualCopy {

    static func line(for elapsedSeconds: TimeInterval, on date: Date = Date()) -> String {
        let tier = QuoteTier.tier(for: elapsedSeconds)
        let bucket = lines[tier] ?? lines[.zeroToThirtyMin]!
        // Combine hour with day-of-week offset so the same open time shows
        // different copy each day of the week.
        let cal = Calendar.current
        let hour = cal.component(.hour, from: date)
        let dayOfWeek = cal.component(.weekday, from: date) - 1 // 0 = Sunday
        return bucket[(hour + dayOfWeek * 3) % bucket.count]
    }

    static let lines: [QuoteTier: [String]] = [

        .zeroToThirtyMin: [
            "The craving window is open. It will close.",
            "Your body is still metabolizing the last hit. Give it 20 minutes.",
            "This is the hardest window. You're already through part of it.",
            "The next 20 minutes are the whole game. Nothing else is required right now.",
            "Every person who has ever broken this habit sat exactly where you are.",
            "The discomfort you feel is the old pattern resisting. That's what resistance feels like.",
            "This window has a floor. You're closer to the other side than you were 5 minutes ago.",
            "The craving is loudest right before it breaks. This might be that moment.",
            "You don't have to win. You just have to wait.",
            "The clock is running. That's the only thing that matters right now.",
        ],

        .thirtyMinToTwoHours: [
            "The dopamine spike has passed. The craving is losing its grip.",
            "Blood glucose is stabilizing. The spike has resolved — what's left is the adjustment.",
            "Processed sugar is engineered to make this moment hard. You're still here.",
            "The peak has passed. What you feel now is the descent, not the climb.",
            "Your blood chemistry is already different than it was an hour ago.",
            "The hardest part of the first hour is behind you.",
            "Insulin is normalizing. The fog, if you feel it, is temporary and chemical.",
        ],

        .twoToSixHours: [
            "Insulin is falling. The fog is chemical, not personal.",
            "Your gut microbiome starts shifting within hours of removing processed sugar.",
            "The craving you had an hour ago was a hormone, not a choice.",
            "By now your liver has cleared the acute fructose load. The system is quieter.",
            "What felt urgent two hours ago is already fading. That's what the 20-minute rule is about.",
            "The biological pull has weakened. What remains is habit — and habits respond to interruption.",
            "Three hours from now this won't feel the same as it does right now.",
        ],

        .sixTo24Hours: [
            "By now your liver has cleared most of the fructose. You're running cleaner.",
            "Sleep tonight may be different. Without the glucose swings, your body has less to manage through the night.",
            "Most people have consumed sugar again by now. You haven't.",
            "Eight hours of clean fuel is a measurable event. Your body is responding to it.",
            "The hardest part of the first day is behind you.",
            "Your cortisol won't spike tonight looking for glucose to stabilize. That's a different night's sleep.",
            "The cravings that showed up today were habit. You showed them something different.",
        ],

        .oneToThreeDays: [
            "Taste receptors regenerate roughly every two weeks. At this stage, the shift has started.",
            "Three days in. The cravings are starting to feel less automatic.",
            "The craving still shows up. But it's quieter than it was yesterday.",
            "Day 2 is where most people convince themselves they don't really need to do this. You're still here.",
            "The physiological pull is almost resolved. What's left is habit — and you're already interrupting it.",
            "The gut microbiome is already responding. Beneficial bacteria populations grow in the absence of their competitor.",
            "Your taste receptors are beginning the process of recovery. It takes two weeks. You've started.",
        ],

        .threeToSevenDays: [
            "After 72 hours, dopamine receptor sensitivity begins to recover.",
            "Around day 4, most people have their first genuine 'I don't actually want it' moment.",
            "By the end of this week, most cravings are habit, not hunger.",
            "The compulsive edge fades around day 3. If it's still showing up, it's dimmer than it was.",
            "Day 5 cravings are almost entirely conditioned responses. The biology has largely resolved.",
            "You're past the hardest part. Most people never get here.",
            "The difference between day 3 and day 7 is larger than most people expect.",
        ],

        .sevenTo14Days: [
            "A week without processed sugar has measurably changed your gut microbiome. That's biology, not motivation.",
            "Most people never stay here long enough to find out what their baseline energy actually feels like.",
            "At this stage the work is identity, not willpower.",
            "Seven days is enough to have changed something real. Two weeks is enough to have changed something durable.",
            "The brain is consolidating the new pattern. Each day makes the next one easier.",
            "Cravings at this stage are echoes of the old pattern, not the pattern itself.",
            "You're in territory that most people have never been in. The view is different here.",
        ],

        .fourteenTo30Days: [
            "Two weeks. Hepatic fat accumulation has slowed. Insulin sensitivity is measurably different for most people at this mark.",
            "Past the point where most people turn back.",
            "At this stage, cravings are mostly memory, not biology. The biology has already shifted.",
            "Most people never find out what their body actually feels like without chronic sugar. You're finding out.",
            "The cognitive clarity at this stage is not placebo. Stable glucose is better fuel for the brain.",
            "Two weeks of reduced insulin means two weeks of reduced visceral fat accumulation.",
            "The improvements at this stage compound quietly. You may already be noticing things you can't quite name.",
            "Slow-wave sleep has had real time to consolidate. The deep rest you may be getting now is a biological outcome, not coincidence.",
            "Your taste receptors are nearly two weeks into recalibrating. The natural world is getting louder.",
            "The inflammation that was running quietly in the background has had two weeks to fall. That's not metaphor — it's CRP.",
            "Habit cravings weaken through exposure without reward. You've been doing that for two weeks. The reflex is fading.",
            "The hardest mile was the first one. You are now in territory most people have never mapped.",
            "Fasting insulin at this mark looks different than it did two weeks ago. Every downstream system follows it.",
            "Identity and behavior are converging. The person who does this and the person you are becoming the same person.",
        ],

        .thirtyPlusDays: [
            "A month. Dopamine receptor sensitivity has had time to begin recovering. The system is different than it was.",
            "You're not trying to quit sugar anymore. You don't eat it.",
            "The neural pathway for the old habit has weakened through disuse. It doesn't disappear — it just loses priority.",
            "This is identity now, not discipline. The hardest work happened weeks ago.",
            "Food tastes different now. That's the receptor sensitivity coming back, not imagination.",
            "Thirty days of quiet work has changed your gut, your sleep, your insulin response, and your brain. It's in the ledger.",
            "The compound interest of this is invisible until it isn't. You're in the middle of it accumulating.",
            "Inflammation is systemic and silent — and it responds to sustained dietary change. Yours is falling.",
            "At this stage the biology is doing the work. You're maintaining, not fighting.",
            "The social version of this is easier now too. Preference has replaced restraint.",
            "Visceral fat — the kind that drives metabolic disease — responds faster to insulin reduction than any other intervention. This is that intervention.",
            "Your gut microbiome at this point is producing more of the neurotransmitters associated with calm and clarity. That's not metaphor.",
            "Glycation — where sugar binds to collagen and accelerates aging — has been actively reversing since you stopped feeding it.",
            "The person who wanted to change this is the same one who is living the change. That's not nothing.",
        ],
    ]
}
