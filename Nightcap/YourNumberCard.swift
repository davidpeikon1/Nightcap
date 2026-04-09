import SwiftUI

// MARK: - Sugar Tier

enum SugarTier {
    case low, moderate, high, veryHigh

    init(grams: Int) {
        switch grams {
        case ..<25:  self = .low
        case 25..<50: self = .moderate
        case 50..<100: self = .high
        default:      self = .veryHigh
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
    @State private var showEdit = false

    private var grams: Int? { appState.dailySugarGrams }
    private var quiz: Int?  { appState.quizSugarGrams }

    private var tier: SugarTier? {
        guard let g = grams else { return nil }
        return SugarTier(grams: g)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("YOUR NUMBER")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Color("NCTextSecondary"))

                Spacer()

                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showEdit = true
                } label: {
                    Text(grams == nil ? "Set it" : "Update")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(Color("NCSuccess"))
                }
            }

            Rectangle()
                .fill(Color("NCTextTertiary").opacity(0.4))
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
        .sheet(isPresented: $showEdit) {
            NumberEditSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private func numberDisplay(grams: Int, tier: SugarTier) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(grams)")
                    .font(.system(size: 48, weight: .light).monospacedDigit())
                    .foregroundStyle(Color("NCTextPrimary"))
                    .contentTransition(.numericText())
                Text("g added sugar / day")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .padding(.bottom, 4)

                Spacer()
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(tier.color)
                    .frame(width: 6, height: 6)
                Text(tier.label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(tier.color)
            }

            Text(tier.biologicalNote)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if let q = quiz, q != grams {
                let delta = q - grams
                Text(delta > 0
                     ? "Down \(delta)g from your original estimate. That's \(delta * 365 / 1000)kg less fructose per year entering your liver."
                     : "Up \(abs(delta))g from your original estimate.")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color("NCTextTertiary"))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .animation(.spring(duration: 0.3), value: grams)
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
