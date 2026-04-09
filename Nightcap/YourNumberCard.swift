import SwiftUI

// MARK: - Sugar Tier

enum SugarTier {
    case low, moderate, high, veryHigh

    init(grams: Int) {
        switch grams {
        case ..<25:    self = .low
        case 25..<50:  self = .moderate
        case 50..<100: self = .high
        default:       self = .veryHigh
        }
    }

    var label: String {
        switch self {
        case .low:      return "Within range"
        case .moderate: return "Above recommended"
        case .high:     return "Significantly elevated"
        case .veryHigh: return "Very high"
        }
    }

    var color: Color {
        switch self {
        case .low:      return Color("NCSuccess")
        case .moderate: return Color("NCWarning")
        case .high:     return Color.orange
        case .veryHigh: return Color.red.opacity(0.8)
        }
    }

    var biologicalNote: String {
        switch self {
        case .low:
            return "Your daily intake is near or below the AHA threshold. Insulin response is minimal and predictable."
        case .moderate:
            return "Above the recommended daily maximum. Your pancreas is compensating daily, and cravings fire on a learned schedule."
        case .high:
            return "Chronic insulin elevation at this level actively suppresses fat mobilization and amplifies dopamine-driven cravings."
        case .veryHigh:
            return "At this level, daily sugar is suppressing dopamine receptor density, disrupting sleep architecture, and driving fat storage as a primary metabolic state."
        }
    }
}

// MARK: - Your Number Card

struct YourNumberCard: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var store: FastingStore
    @State private var showEdit = false
    @State private var updatePulse: Double = 1.0
    @State private var biologyExpanded = false

    private var grams: Int? { appState.dailySugarGrams }
    private var quiz: Int?  { appState.quizSugarGrams }

    private var tier: SugarTier? {
        guard let g = grams else { return nil }
        return SugarTier(grams: g)
    }

    /// True when the number hasn't been updated in > 30 days.
    private var isStale: Bool {
        guard let updated = appState.dailySugarGramsUpdated else { return false }
        return Date().timeIntervalSince(updated) > 30 * 86400
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Text("YOUR NUMBER")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Color("NCTextSecondary"))

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showEdit = true
                } label: {
                    HStack(spacing: 4) {
                        if isStale {
                            Circle()
                                .fill(Color("NCWarning"))
                                .frame(width: 5, height: 5)
                                .scaleEffect(updatePulse)
                                .onAppear {
                                    withAnimation(
                                        .easeInOut(duration: 1.2)
                                        .repeatForever(autoreverses: true)
                                    ) { updatePulse = 1.5 }
                                }
                        }
                        Text(grams == nil ? "Set it" : "Update")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(isStale ? Color("NCWarning") : Color("NCSuccess"))
                    }
                }
            }

            Rectangle()
                .fill(Color("NCTextTertiary").opacity(0.35))
                .frame(height: 1)
                .padding(.top, 12)
                .padding(.bottom, 16)

            if let g = grams, let t = tier {
                numberDisplay(grams: g, tier: t)
            } else {
                emptyState
            }
        }
        .padding(20)
        .background(Color("NCSurface"))
        .cornerRadius(16)
        .animation(.spring(duration: 0.3), value: biologyExpanded)
        .sheet(isPresented: $showEdit) {
            NumberEditSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private func numberDisplay(grams: Int, tier: SugarTier) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Hero number
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(grams)")
                    .font(.system(size: 52, weight: .light).monospacedDigit())
                    .foregroundStyle(Color("NCTextPrimary"))
                    .contentTransition(.numericText())
                Text("g / day")
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .padding(.bottom, 5)
                Spacer()
            }

            // Tier chip + "The biology" expand toggle on same row
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(tier.color)
                        .frame(width: 6, height: 6)
                    Text(tier.label)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(tier.color)
                }
                Spacer()
                Button {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    withAnimation(.spring(duration: 0.3)) { biologyExpanded.toggle() }
                } label: {
                    HStack(spacing: 4) {
                        Text("The biology")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(Color("NCTextTertiary"))
                        Image(systemName: biologyExpanded ? "chevron.up" : "chevron.right")
                            .font(.system(size: 10, weight: .light))
                            .foregroundStyle(Color("NCTextTertiary"))
                    }
                }
            }

            // Bio note — expandable, hidden by default to reduce card density
            if biologyExpanded {
                Text(tier.biologicalNote)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Target benchmark — gives the number a clear direction
            targetBenchmark(grams: grams, tier: tier)

            // Sugar avoided — only shown after a meaningful stretch so the
            // number isn't inflated for someone 10 minutes into their fast.
            if store.elapsedSeconds >= 6 * 3600 {
                avoidedStat(grams: grams)
            }

            // Delta vs quiz estimate
            if let q = quiz, q != grams {
                let delta = q - grams
                Text(delta > 0
                     ? "Down \(delta)g from your original estimate. That's \(delta * 365 / 1_000)kg less fructose per year entering your liver."
                     : "Up \(abs(delta))g from your original estimate.")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color("NCTextTertiary"))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Stale update prompt
            if isStale {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(Color("NCWarning"))
                    Text("It's been a while. Has your number changed?")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color("NCWarning").opacity(0.85))
                }
                .padding(.top, 2)
            }
        }
        .animation(.spring(duration: 0.3), value: grams)
    }

    private func targetBenchmark(grams: Int, tier: SugarTier) -> some View {
        let target = 25
        let diff = grams - target
        return Group {
            if diff <= 0 {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(Color("NCSuccess"))
                    Text("Within the AHA recommended limit of 25g / day.")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color("NCSuccess").opacity(0.85))
                }
            } else {
                Text("\(diff)g above the AHA-recommended 25g / day. The goal: bring this number down.")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color("NCTextTertiary"))
                    .lineSpacing(3)
            }
        }
    }

    private func avoidedStat(grams: Int) -> some View {
        let days = max(1, Int(store.elapsedSeconds / 86400))
        let totalGrams = days * grams
        let teaspoons = totalGrams / 4
        let label: String = {
            if days == 1 {
                return "Today: ~\(totalGrams)g of added sugar not processed — about \(teaspoons) teaspoons."
            } else {
                return "\(days) days in: ~\(totalGrams)g of added sugar not processed — about \(teaspoons) teaspoons."
            }
        }()
        return Text(label)
            .font(.system(size: 13, weight: .light))
            .foregroundStyle(Color("NCSuccess").opacity(0.85))
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .contentTransition(.numericText())
            .animation(.snappy(duration: 0.25), value: days)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How much added sugar are you having per day?")
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Text("Your number shapes how the app explains what's happening in your body.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showEdit = true
            } label: {
                Text("Set my number")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color("NCBackground"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color("NCAccent"))
                    .cornerRadius(10)
            }
            .padding(.top, 4)
        }
    }
}
