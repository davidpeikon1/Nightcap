import SwiftUI
import StoreKit

// MARK: - Progress Section

struct ProgressSection: View {
    @EnvironmentObject var store: FastingStore
    @State private var selectedBadge: BadgeID? = nil
    @State private var showHistory = false

    private var orderedBadges: [BadgeID] {
        BadgeID.allCases
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("YOUR PROGRESS")
                    .font(.system(size: 11, weight: .medium))
                    .tracking(2)
                    .foregroundStyle(Color("NCTextSecondary"))
                Spacer()
                Button {
                    showHistory = true
                } label: {
                    HStack(spacing: 4) {
                        Text("History")
                            .font(.system(size: 12))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .light))
                    }
                    .foregroundStyle(Color("NCTextSecondary"))
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(orderedBadges, id: \.self) { badge in
                        BadgeView(badge: badge, earned: store.earnedBadges.contains(badge))
                            .onTapGesture {
                                if store.earnedBadges.contains(badge) {
                                    selectedBadge = badge
                                }
                            }
                    }
                }
                .padding(.horizontal, 1) // prevent clipping
            }

            // Phase progress bar
            phaseProgressView
        }
        .sheet(isPresented: $showHistory) {
            FastHistoryView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailView(badge: badge)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var phaseProgressView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(store.fastingPhase.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color("NCTextPrimary"))

                Spacer()

                Text(store.timeToNextMilestone)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color("NCTextTertiary"))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color("NCSurface"))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color("NCSuccess"))
                        .frame(width: geo.size.width * store.phaseProgress, height: 6)
                        .animation(.spring(duration: 0.8), value: store.phaseProgress)
                }
            }
            .frame(height: 6)

            Text(store.fastingPhase.tagline)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
        }
        .padding(16)
        .background(Color("NCSurface"))
        .cornerRadius(12)
    }
}

// MARK: - Badge View

struct BadgeView: View {
    let badge: BadgeID
    let earned: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(earned ? Color("NCSuccess").opacity(0.12) : Color("NCSurface"))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(
                                earned ? Color("NCSuccess").opacity(0.4) : Color("NCTextTertiary").opacity(0.3),
                                lineWidth: 1
                            )
                    )

                Image(systemName: badge.symbol)
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(earned ? Color("NCSuccess") : Color("NCTextTertiary"))
            }

            Text(badge.label)
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(earned ? Color("NCTextPrimary") : Color("NCTextTertiary"))
                .multilineTextAlignment(.center)
                .frame(width: 60)
        }
    }
}

// MARK: - Badge Detail

struct BadgeDetailView: View {
    let badge: BadgeID
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color("NCBackground").ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color("NCSuccess").opacity(0.1))
                        .frame(width: 100, height: 100)

                    Image(systemName: badge.symbol)
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(Color("NCSuccess"))
                }

                VStack(spacing: 10) {
                    Text(badge.label)
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))

                    Text(badge.celebrationText)
                        .font(.system(size: 17, weight: .light))
                        .foregroundStyle(Color("NCTextSecondary"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 32)
                }

                Text(badge.scienceFact)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Keep going")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(Color("NCBackground"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color("NCAccent"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Milestone Sheet (for in-app popups)

struct MilestoneSheet: View {
    let badge: BadgeID
    @EnvironmentObject var store: FastingStore
    @Environment(\.dismiss) var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var shareImage: UIImage? = nil
    @State private var showShareSheet = false

    var body: some View {
        ZStack {
            Color("NCBackground").ignoresSafeArea()

            // Confetti for major milestones
            if badge.useConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .zIndex(1)
            }

            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color("NCSuccess").opacity(0.08))
                        .frame(width: 80, height: 80)
                    Image(systemName: badge.symbol)
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(Color("NCSuccess"))
                }

                Text(badge.label + ".")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(Color("NCTextPrimary"))

                Text(badge.celebrationText)
                    .font(.system(size: 17, weight: .light))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 32)

                Text(badge.scienceFact)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color("NCTextTertiary"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)

                Spacer()

                VStack(spacing: 12) {
                    // Share button
                    Button {
                        Task { @MainActor in
                            shareImage = makeShareImage(
                                badge: badge,
                                elapsedSeconds: store.elapsedSeconds
                            )
                            showShareSheet = shareImage != nil
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .light))
                            Text("Share this milestone")
                                .font(.system(size: 15, weight: .regular))
                        }
                        .foregroundStyle(Color("NCTextSecondary"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("NCSurface"))
                        .cornerRadius(12)
                    }

                    Button {
                        store.dismissBadge()
                        dismiss()
                    } label: {
                        Text("Keep going")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color("NCBackground"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color("NCAccent"))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .zIndex(2)
        }
        .sheet(isPresented: $showShareSheet) {
            if let img = shareImage {
                ShareSheet(items: [img])
                    .presentationDetents([.medium, .large])
            }
        }
        .onAppear {
            // Request a review at the 1-week milestone — a high-satisfaction moment.
            // Apple allows 3 prompts per year; this fires only once (badge earned once).
            if badge == .oneWeek {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    requestReview()
                }
            }
        }
    }
}

// MARK: - UIActivityViewController wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
