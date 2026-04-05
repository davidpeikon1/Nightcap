import SwiftUI

struct PhaseDetailSheet: View {
    let phase: FastingPhase
    @EnvironmentObject var store: FastingStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color("NCBackground").ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        phaseHeader
                        timelineSection
                        scienceSection
                        tipsSection
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
            }
            .navigationTitle(phase.rawValue)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color("NCAccent"))
                        .fontWeight(.medium)
                }
            }
        }
    }

    // MARK: - Phase Header

    private var phaseHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Circle()
                    .fill(phaseColor)
                    .frame(width: 8, height: 8)
                Text(phase.tagline)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Color("NCTextSecondary"))
                Spacer()
                // When viewing the current phase, show how long the user has been in it.
                if phase == store.fastingPhase, let timeInPhase = timeInPhaseText {
                    Text(timeInPhase)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(phaseColor.opacity(0.7))
                }
            }

            Text(phase.bodyScience)
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// How long the user has been in the current phase.
    /// Returns nil for phases other than the current one, or when not tracking.
    private var timeInPhaseText: String? {
        guard let start = store.lastSugarDate else { return nil }
        let entryDate = start.addingTimeInterval(phase.previousThreshold)
        let seconds = max(0, Date().timeIntervalSince(entryDate))
        let h = Int(seconds) / 3600
        let d = h / 24
        let m = (Int(seconds) % 3600) / 60
        if d >= 7  { return "\(d)d in this phase" }
        if d >= 1  { let rh = h % 24; return rh > 0 ? "\(d)d \(rh)h in this phase" : "\(d)d in this phase" }
        if h >= 1  { return m > 0 ? "\(h)h \(m)m in this phase" : "\(h)h in this phase" }
        return "\(m)m in this phase"
    }

    // MARK: - Phase Timeline

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("THE FULL JOURNEY")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundStyle(Color("NCTextSecondary"))

            VStack(spacing: 0) {
                ForEach(Array(FastingPhase.allCases.enumerated()), id: \.element) { idx, p in
                    timelineRow(p, isLast: idx == FastingPhase.allCases.count - 1)
                }
            }
        }
    }

    private func timelineRow(_ p: FastingPhase, isLast: Bool) -> some View {
        let isCurrent = p == phase

        return HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(isCurrent ? phaseColor : (
                        p.previousThreshold < phase.previousThreshold
                        ? Color("NCSuccess").opacity(0.6)
                        : Color("NCTextTertiary").opacity(0.3)
                    ))
                    .frame(width: 10, height: 10)
                    .padding(.top, 5)

                if !isLast {
                    Rectangle()
                        .fill(Color("NCTextTertiary").opacity(0.25))
                        .frame(width: 1)
                        .frame(minHeight: 36)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(p.rawValue)
                        .font(.system(size: 14, weight: isCurrent ? .medium : .regular))
                        .foregroundStyle(isCurrent ? phaseColor : Color("NCTextPrimary"))
                    if isCurrent {
                        Text("you are here")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(phaseColor)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(phaseColor.opacity(0.12))
                            .cornerRadius(4)
                        if let entryDate = phaseEntryDate(for: p) {
                            Text(relativeDate(entryDate))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(phaseColor.opacity(0.7))
                        }
                    }
                    Spacer()
                    Text(p.milestoneLabel)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(Color("NCTextTertiary"))
                }
                Text(p.tagline)
                    .font(.system(size: 12))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .padding(.bottom, 14)
            }
        }
    }

    // MARK: - Science Section

    private var scienceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("WHAT'S HAPPENING BIOLOGICALLY")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundStyle(Color("NCTextSecondary"))

            VStack(alignment: .leading, spacing: 12) {
                ForEach(bioPoints, id: \.self) { point in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "flask")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Color("NCSuccess"))
                            .padding(.top, 2)
                        Text(point)
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Color("NCTextPrimary"))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .background(Color("NCSurface"))
            .cornerRadius(12)
        }
    }

    // MARK: - Tips Section

    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("TIPS FOR THIS PHASE")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundStyle(Color("NCTextSecondary"))

            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .light))
                            .foregroundStyle(Color("NCWarning"))
                            .padding(.top, 3)
                        Text(tip)
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Color("NCTextPrimary"))
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .background(Color("NCSurface"))
            .cornerRadius(12)
        }
    }

    // MARK: - Helpers

    private func phaseEntryDate(for p: FastingPhase) -> Date? {
        guard let start = store.lastSugarDate else { return nil }
        return start.addingTimeInterval(p.previousThreshold)
    }

    private func relativeDate(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }

    // MARK: - Data

    private var phaseColor: Color {
        switch phase {
        case .justStarted:  return Color("NCTextTertiary")
        case .firstDay:     return Color("NCWarning")
        case .withdrawal:   return .red.opacity(0.75)
        case .breakthrough: return .orange
        case .rewiring:     return .teal
        case .freedom:      return Color("NCSuccess")
        }
    }

    private var bioPoints: [String] {
        switch phase {
        case .justStarted: return [
            "Blood glucose begins stabilizing within 30–60 minutes. The craving peak is neurological, not metabolic.",
            "Dopamine is released in anticipation of the habitual reward. The brain is looking for what it expects — not what the body needs.",
        ]
        case .firstDay: return [
            "Hepatic glycogen (liver sugar storage) depletes within 12–24 hours, initiating a metabolic substrate shift.",
            "Ghrelin, the hunger hormone, spikes in response to habitual eating cues — even when no genuine hunger exists.",
            "Insulin begins falling toward baseline as glucose intake drops.",
        ]
        case .withdrawal: return [
            "Chronic dopamine spikes had suppressed D2 receptor density. Without the overstimulation, the upregulation process initiates — but the perceptible benefit doesn't arrive until the breakthrough phase.",
            "Serotonin production, 90% of which occurs in the gut, is disrupted as the microbiome shifts composition rapidly.",
            "Headaches and brain fog are caused by reactive hypoglycemia as the brain recalibrates its baseline energy expectations.",
        ]
        case .breakthrough: return [
            "Taste receptor sensitivity for sweetness begins recovering — downregulated by chronic sugar exposure, now upregulating.",
            "The mesolimbic dopamine system (reward center) begins restabilizing. The compulsive edge of cravings drops measurably.",
            "Firmicutes bacteria (which drive fat storage and sugar cravings) begin dying off; Bacteroidetes start growing.",
        ]
        case .rewiring: return [
            "Gut microbiome composition has measurably shifted within 7 days. Craving-amplifying bacteria have decreased significantly.",
            "Insulin sensitivity improves measurably. The liver begins clearing fructose-derived fat deposits.",
            "Slow-wave sleep quality improves as blood sugar no longer spikes and crashes through the night.",
            "fMRI studies show reduced reward-center activation in response to sugar-related images at the 7-day mark.",
        ]
        case .freedom: return [
            "D2 receptor density — suppressed by chronic dopaminergic overstimulation — has had meaningful recovery time.",
            "Glycation (the process where sugar molecules bind to and damage collagen and other proteins) is actively reversing.",
            "Advanced glycation end-products (AGEs), a primary driver of accelerated aging and inflammation, are declining.",
            "Neural pathways for the old habit have weakened through disuse; the new pattern has strengthened through repetition.",
        ]
        }
    }

    private var tips: [String] {
        switch phase {
        case .justStarted: return [
            "Water helps — hunger and craving feel physiologically identical. Water resolves one of them.",
            "The 20-minute rule: set a timer. Cravings almost always pass before it goes off.",
            "Observing a craving rather than fighting it reduces its intensity. Try naming it: 'This is a craving. It will pass.'",
        ]
        case .firstDay: return [
            "Stay out of the kitchen unless you're cooking a full meal. Environmental triggers are documented and real.",
            "Eat something protein-rich and fatty — eggs, nuts, avocado. Fat slows glucose absorption and reduces ghrelin.",
            "Expect a dip in energy around hour 12–16. It's the glycogen running out, not your body failing.",
        ]
        case .withdrawal: return [
            "This is the valley. If you feel irritable or foggy, you're right on schedule. Most people quit here.",
            "Rest more than usual. Sleep is your highest leverage tool for getting through withdrawal faster.",
            "Add magnesium if you have it — it reduces the cortisol response that's driving your irritability.",
            "Don't make major decisions today. Your prefrontal cortex is temporarily compromised by the withdrawal.",
        ]
        case .breakthrough: return [
            "By day 4 the craving is almost entirely habit, not hunger. The two feel physiologically identical — but the biological pull has already resolved.",
            "Natural sweetness is starting to register differently. Fruit and plain dairy now hit receptors that processed sugar had desensitized.",
            "The craving at this stage is a conditioned response looking for its cue. Disrupting the cue — different route, different room — disrupts the response.",
        ]
        case .rewiring: return [
            "At one week, the bacteria that amplify sugar cravings have decreased measurably. The gut is changing the signal, not just the behavior.",
            "Replacement rituals form fastest when the cue is kept but the routine changes. Same time, same place — different action.",
            "Talking about a commitment to someone else increases follow-through significantly. The mechanism is self-concept consistency, not accountability.",
        ]
        case .freedom: return [
            "At social events, preference has replaced restraint for most people at this stage. 'I don't eat that' carries a different weight than 'I'm trying not to.'",
            "Any lapse now is data. The context, the trigger, the time of day — it all maps to a pattern that can be read and interrupted.",
            "Taste receptors have reset. What was ordinary before now has more depth. That's receptor sensitivity recovering, not imagination.",
        ]
        }
    }
}
