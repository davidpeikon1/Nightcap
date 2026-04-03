import SwiftUI

struct WeeklyInsightCard: View {
    @EnvironmentObject var store: FastingStore
    @State private var isDismissed = false

    var body: some View {
        Group {
            if let insight = store.weeklyInsight, !isDismissed {
                cardView(insight)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.4), value: isDismissed)
    }

    private func cardView(_ insight: WeeklyInsight) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("THIS WEEK")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundStyle(Color("NCTextSecondary"))

            // Stats
            VStack(spacing: 10) {
                statRow("Longest fast", value: insight.longestFastFormatted)
                statRow("Resets", value: "\(insight.resetCount)")
                if let trigger = insight.topTrigger {
                    statRow("Most common trigger", value: trigger.rawValue)
                }
            }

            Rectangle()
                .fill(Color("NCTextTertiary").opacity(0.4))
                .frame(height: 1)

            // Insight copy
            Text(insight.insightCopy)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                withAnimation { isDismissed = true }
            } label: {
                Text("Dismiss")
                    .font(.system(size: 13))
                    .foregroundStyle(Color("NCTextTertiary"))
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color("NCSurface"))
        .cornerRadius(16)
    }

    private func statRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color("NCTextSecondary"))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundStyle(Color("NCTextPrimary"))
        }
    }
}
