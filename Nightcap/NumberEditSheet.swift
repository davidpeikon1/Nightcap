import SwiftUI

struct NumberEditSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var sliderValue: Double
    @State private var savedReduction: Int? = nil   // set when user saves a lower number

    init() {
        // Default to current value or 50g if unset
        let current = UserDefaults.standard.object(forKey: "dailySugarGrams") as? Int ?? 50
        _sliderValue = State(initialValue: Double(current))
    }

    private var grams: Int { Int(sliderValue / 5) * 5 }   // snap to 5g steps
    private var tier: SugarTier { SugarTier(grams: grams) }

    var body: some View {
        ZStack {
            editView

            if let reduction = savedReduction {
                successView(reduction: reduction)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: savedReduction)
    }

    // MARK: - Edit View

    private var editView: some View {
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
                    let previous = appState.dailySugarGrams
                    if appState.quizSugarGrams == nil {
                        appState.quizSugarGrams = grams
                    }
                    appState.dailySugarGrams = grams
                    // Celebrate a reduction — this is the core retention moment
                    if let prev = previous, grams < prev {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        withAnimation { savedReduction = prev - grams }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            dismiss()
                        }
                    } else {
                        dismiss()
                    }
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

    // MARK: - Success View (shown when user reduces their number)

    private func successView(reduction: Int) -> some View {
        let kgPerYear = Double(reduction) * 365.0 / 1000.0
        return VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Color("NCSuccess"))

                VStack(spacing: 8) {
                    Text("\(reduction)g less per day")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))

                    Text(String(format: "That's %.1fkg of added sugar less entering your liver each year.", kgPerYear))
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color("NCBackground"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("NCAccent"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color("NCBackground").ignoresSafeArea())
    }
}
