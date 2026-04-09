import SwiftUI

struct NumberEditSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var sliderValue: Double

    init() {
        // Default to current value or 50g if unset
        let current = UserDefaults.standard.object(forKey: "dailySugarGrams") as? Int ?? 50
        _sliderValue = State(initialValue: Double(current))
    }

    private var grams: Int { Int(sliderValue / 5) * 5 }   // snap to 5g steps
    private var tier: SugarTier { SugarTier(grams: grams) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Your Daily Number")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Color("NCTextPrimary"))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color("NCTextSecondary"))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 20)

            // Number display
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(grams)")
                    .font(.system(size: 56, weight: .light).monospacedDigit())
                    .foregroundStyle(Color("NCTextPrimary"))
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.15), value: grams)
                Text("g / day")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .padding(.bottom, 6)
            }
            .padding(.horizontal, 24)

            // Tier indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(tier.color)
                    .frame(width: 7, height: 7)
                Text(tier.label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(tier.color)
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
            .animation(.spring(duration: 0.2), value: tier.label)

            // Slider
            Slider(value: $sliderValue, in: 0...200, step: 5)
                .tint(tier.color)
                .padding(.horizontal, 24)
                .padding(.top, 20)

            HStack {
                Text("0g")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color("NCTextTertiary"))
                Spacer()
                Text("100g (US avg)")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color("NCTextTertiary"))
                Spacer()
                Text("200g")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color("NCTextTertiary"))
            }
            .padding(.horizontal, 24)
            .padding(.top, 4)

            // Biological note
            Text(tier.biologicalNote)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .animation(.easeInOut(duration: 0.2), value: tier.biologicalNote)

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if appState.quizSugarGrams == nil {
                        appState.quizSugarGrams = grams
                    }
                    appState.dailySugarGrams = grams
                    dismiss()
                } label: {
                    Text("Save")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color("NCBackground"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("NCAccent"))
                        .cornerRadius(12)
                }

                Text("Not sure? Take the sugar quiz at drinknightcap.co")
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color("NCTextTertiary"))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color("NCBackground").ignoresSafeArea())
    }
}
