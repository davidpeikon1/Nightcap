import SwiftUI

struct DailyReframeCard: View {
    @EnvironmentObject var store: FastingStore
    @State private var scienceExpanded = false

    private var quote: ReframeQuote {
        QuoteLibrary.dailyQuote(for: store.elapsedSeconds)
    }

    private var dayCount: Int {
        max(1, Int(store.elapsedSeconds / 86400) + 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("TODAY'S REFRAME")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Color("NCTextSecondary"))

                Spacer()

                Text("day \(dayCount)")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color("NCTextTertiary"))
            }

            Rectangle()
                .fill(Color("NCTextTertiary").opacity(0.4))
                .frame(height: 1)
                .padding(.top, 12)
                .padding(.bottom, 20)

            // Quote
            Text(quote.text)
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))
                .lineSpacing(7)
                .fixedSize(horizontal: false, vertical: true)

            // Expandable science
            VStack(alignment: .leading, spacing: 0) {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        scienceExpanded.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text("The science")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color("NCSuccess"))

                        Image(systemName: scienceExpanded ? "chevron.up" : "chevron.right")
                            .font(.system(size: 10, weight: .light))
                            .foregroundStyle(Color("NCSuccess"))
                    }
                    .padding(.top, 18)
                }

                if scienceExpanded {
                    Text(quote.science)
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 12)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .padding(20)
        .background(Color("NCSurface"))
        .cornerRadius(16)
        .animation(.spring(duration: 0.3), value: scienceExpanded)
    }
}
