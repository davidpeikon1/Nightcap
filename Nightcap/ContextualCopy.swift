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
            "This window closes in under 20 minutes. It's the only one that needs closing right now.",
            "There are two outcomes from the next 20 minutes. You already know which one you want.",
            "The craving has a ceiling. You're underneath it. Once you're through it, it's done.",
        ],

        .thirtyMinToTwoHours: [
            "The dopamine spike has passed. The craving is losing its grip.",
            "Blood glucose is stabilizing. The spike has resolved — what's left is the adjustment.",
            "Processed sugar is engineered to make this moment hard. You're still here.",
            "The peak has passed. What you feel now is the descent, not the climb.",
            "Your blood chemistry is already different than it was an hour ago.",
            "The hardest part of the first hour is behind you.",
            "Insulin is normalizing. The fog, if you feel it, is temporary and chemical.",
            "The blood sugar spike that started this has already peaked. What you're feeling now is the descent.",
            "The brain's reward signal is quieter now than it was 30 minutes ago. The urgency was the peak.",
            "Two hours from now you won't remember this moment with the same intensity. That's not optimism — that's neurochemistry.",
        ],

        .twoToSixHours: [
            "Insulin is falling. The fog is chemical, not personal.",
            "Your gut microbiome starts shifting within hours of removing processed sugar.",
            "The craving you had an hour ago was a hormone, not a choice.",
            "By now your liver has cleared the acute fructose load. The system is quieter.",
            "The acute pull is over. What remains is the echo — and echoes fade.",
            "The biological pull has weakened. What remains is habit — and habits respond to interruption.",
            "Three hours from now this won't feel the same as it does right now.",
            "By hour 3, the acute fructose load your liver was processing has largely cleared. The metabolic noise is quieter.",
            "The habitual hunger signal fires on a schedule, not a need. What you feel right now is the schedule, not your body asking for anything.",
            "Insulin is measurably lower right now than it was a few hours ago. Every downstream system responds to that drop.",
        ],

        .sixTo24Hours: [
            "By now your liver has cleared most of the fructose. You're running cleaner.",
            "Sleep tonight may be different. Without the glucose swings, your body has less to manage through the night.",
            "Most people have consumed sugar again by now. You haven't.",
            "Eight hours of clean fuel is a measurable event. Your body is responding to it.",
            "The hardest part of the first day is behind you.",
            "Your cortisol won't spike tonight looking for glucose to stabilize. That's a different night's sleep.",
            "The cravings that showed up today were habit. You showed them something different.",
            "The first 12 hours are the metabolic handoff — your body shifting fuel sources. The flat feeling is the transition, not your baseline.",
            "The cravings today are schedule-based, not need-based. Your body ate at this time yesterday. The expectation is wrong — and it will weaken.",
            "By the end of today, your liver's glycogen reserves will be significantly depleted. Tomorrow's energy runs on a different substrate.",
        ],

        .oneToThreeDays: [
            "Taste receptors regenerate roughly every two weeks. At this stage, the shift has started.",
            "Three days in. The cravings are starting to feel less automatic.",
            "The craving still shows up. But it's quieter than it was yesterday.",
            "Day 2 is where most people convince themselves they don't really need to do this. You're still here.",
            "The physiological pull is almost resolved. What's left is habit — and you're already interrupting it.",
            "The gut microbiome is already responding. Beneficial bacteria populations grow in the absence of their competitor.",
            "Dopamine receptor sensitivity begins recovering around 72 hours. The biology is already turning.",
            "The cravings between days 1 and 3 are withdrawal, not hunger. The body is not asking for sugar — it is asking for its baseline back.",
            "At 48 hours, most of the acute fructose signaling has resolved. What arrives now is the conditioned schedule, not the biology.",
            "The liver's glycogen-to-fat conversion pathway has quieted. The metabolic noise that drove yesterday's cravings is lower today.",
            "Day 2 has the highest dropout rate of any window. If you're reading this, you're past the most statistically dangerous moment.",
            "Sleep architecture begins improving around day 2. Less cortisol chasing glucose through the night means more slow-wave recovery.",
            "The inflammatory signaling tied to processed sugar has been dropping for 48 hours. It doesn't announce itself — it just quietly resolves.",
        ],

        .threeToSevenDays: [
            "Past 72 hours, dopamine receptor sensitivity begins recovering. The system is already different than it was on day one.",
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
            "Hepatic fat accumulation has slowed. Insulin sensitivity is measurably different at this stage — and it keeps improving.",
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
            "Identity and behavior are converging. The person who does this and the person you are becoming are the same person.",
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
            "The 3am cortisol spike that glucose crashes used to trigger hasn't fired in a long time. Your sleep architecture is different.",
            "Glycation — where sugar binds to collagen and accelerates biological aging — has been actively reversing for weeks.",
            "Your gut-brain axis is producing different neurochemistry. 90% of serotonin is made in the gut — and your gut has changed.",
            "What used to require willpower is now just what you do. That's not discipline. That's identity.",
            "The neurons that encoded the old habit are still there. Their connections have weakened through disuse. That's rewiring, not restraint.",
            "Insulin sensitivity at this mark has shifted enough to be clinically meaningful. Every downstream system follows.",
            "Processed sugar accelerates cellular aging through glycation and oxidative stress. You've been actively slowing that process.",
            "CRP, IL-6, fasting insulin — the chronic disease risk markers. All of them have had time to fall. They have.",
            "Most people who maintain this past 90 days don't think of it as maintenance. It's just how they eat.",
            "The taste of processed sugar, when you encounter it, is different now. The receptors have recovered.",
            "The gut microbiome shift at this length is structural, not transient. The craving-amplifying bacteria are no longer dominant.",
            "What researchers call 'habit extinction' is what you're living. The stimulus exists. The compulsive response doesn't.",
            "The compound interest of months of lower insulin is in your body — in the collagen, the liver, the adipose tissue, the brain.",
            "You've been making tomorrow easier every day for over a month. The balance sheet is different now.",
            "The cognitive clarity you may be experiencing is a real physiological outcome of stable blood glucose. Not placebo.",
            "Six months of clean fuel is a different biological story than one month. Every system has had time to recalibrate.",
            "Your baseline is now established. What you feel on a clean day is what your biology actually looks like.",
            "The cardiovascular changes that come with lower fasting insulin have been compounding quietly. They're in the ledger.",
        ],
    ]
}
