import SwiftUI

// MARK: - Shareable card (rendered by ImageRenderer)

struct ShareCardView: View {
    let badge: BadgeID
    let elapsedSeconds: TimeInterval

    var body: some View {
        VStack(spacing: 0) {
            // Top accent stripe
            Rectangle()
                .fill(Color("NCSuccess"))
                .frame(height: 3)

            VStack(spacing: 24) {
                // Wordmark
                Text("nightcap")
                    .font(.system(size: 13, weight: .light))
                    .tracking(3)
                    .foregroundStyle(Color("NCTextTertiary"))
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
        if d >= 1 { return "\(d)d \(h)h sugar-free" }
        if h >= 1 { return "\(h)h \(m)m sugar-free" }
        return "\(m) minutes sugar-free"
    }
}

// MARK: - Share helper

@MainActor
func makeShareImage(badge: BadgeID, elapsedSeconds: TimeInterval) -> UIImage? {
    let renderer = ImageRenderer(
        content: ShareCardView(badge: badge, elapsedSeconds: elapsedSeconds)
            .preferredColorScheme(.light)
    )
    renderer.scale = UIScreen.main.scale
    return renderer.uiImage
}
