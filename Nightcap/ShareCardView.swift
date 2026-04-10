import SwiftUI

// MARK: - Shareable card (rendered by ImageRenderer)

struct ShareCardView: View {
    let badge: BadgeID
    let elapsedSeconds: TimeInterval
    var reductionGrams: Int? = nil   // grams reduced vs. original quiz estimate

    var body: some View {
        VStack(spacing: 0) {
            // Top accent stripe
            Rectangle()
                .fill(Color("NCSuccess"))
                .frame(height: 3)

            VStack(spacing: 24) {
                // Wordmark
                Image("NightcapLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 16)
                    .padding(.top, 32)

                // Badge
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color("NCSuccess").opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: badge.symbol)
                            .font(.system(size: 34, weight: .light))
                            .foregroundStyle(Color("NCSuccess"))
                    }

                    Text(badge.label)
                        .font(.system(size: 30, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))
                }

                // Elapsed
                Text(formattedElapsed)
                    .font(.system(size: 17, weight: .light).monospacedDigit())
                    .foregroundStyle(Color("NCTextSecondary"))

                // Science fact
                Text(badge.scienceFact)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                // Reduction callout — makes the card meaningful to viewers,
                // not just "X days" but evidence of a real dietary change.
                if let r = reductionGrams, r > 0 {
                    Text("Down \(r)g / day from where I started.")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color("NCSuccess").opacity(0.75))
                        .multilineTextAlignment(.center)
                }

                // Footer
                Text("nightcap · sugar-free tracker")
                    .font(.system(size: 10, weight: .light))
                    .tracking(1)
                    .foregroundStyle(Color("NCTextTertiary"))
                    .padding(.bottom, 32)
            }
        }
        .frame(width: 340)
        .background(Color("NCBackground"))
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 20, y: 8)
    }

    private var formattedElapsed: String {
        let total = Int(elapsedSeconds)
        let d = total / 86400
        let h = (total % 86400) / 3600
        let m = (total % 3600) / 60
        if d >= 7 { return "\(d) days sugar-free" }
        if d >= 1 { return h > 0 ? "\(d)d \(h)h sugar-free" : "\(d)d sugar-free" }
        if h >= 1 { return m > 0 ? "\(h)h \(m)m sugar-free" : "\(h)h sugar-free" }
        return "\(m) minutes sugar-free"
    }
}

// MARK: - Share helper

@MainActor
func makeShareImage(badge: BadgeID, elapsedSeconds: TimeInterval, reductionGrams: Int? = nil) -> UIImage? {
    let renderer = ImageRenderer(
        content: ShareCardView(badge: badge, elapsedSeconds: elapsedSeconds, reductionGrams: reductionGrams)
            .preferredColorScheme(.light)
    )
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage
}
