import SwiftUI
import StoreKit
import UIKit

// MARK: - Progress Section

struct ProgressSection: View {
    @EnvironmentObject var store: FastingStore
    @State private var selectedBadge: BadgeID? = nil
    @State private var selectedLockedBadge: BadgeID? = nil
    @State private var showHistory = false
    @State private var progressFilled = false

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
                Text("\(store.earnedBadges.count)/\(BadgeID.allCases.count)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color("NCTextTertiary"))
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

            ZStack(alignment: .trailing) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(orderedBadges, id: \.self) { badge in
                            BadgeView(badge: badge, earned: store.earnedBadges.contains(badge))
                                .onTapGesture {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    if store.earnedBadges.contains(badge) {
                                        selectedBadge = badge
                                    } else if store.isTracking {
                                        selectedLockedBadge = badge
                                    }
                                    // If not tracking: haptic fires but no sheet opens (intentional)
                                }
                        }
                    }
                    .padding(.horizontal, 1) // prevent clipping
                }

                // Right-edge fade hint — indicates more badges to scroll to
                LinearGradient(
                    colors: [Color("NCBackground").opacity(0), Color("NCBackground")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 32)
                .allowsHitTesting(false)
            }

            // Next badge callout or all-earned celebration
            if let next = nextUnearnedBadge {
                nextBadgeRow(next)
            } else if store.earnedBadges.count == BadgeID.allCases.count && store.isTracking {
                allBadgesEarnedRow
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
        .sheet(item: $selectedLockedBadge) { badge in
            LockedBadgeSheet(badge: badge)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }

    private var phaseProgressView: some View {
        let isFreedom = store.fastingPhase == .freedom
        let dayCount  = Int(store.elapsedSeconds / 86400) + 1
        let rightLabel = isFreedom
            ? "day \(dayCount)"
            : store.timeToNextMilestone

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(store.fastingPhase.rawValue)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color("NCTextPrimary"))

                Spacer()

                Text(rightLabel)
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundStyle(isFreedom ? Color("NCSuccess").opacity(0.8) : Color("NCTextTertiary"))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color("NCTextTertiary").opacity(0.25))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color("NCSuccess"))
                        .frame(width: geo.size.width * (progressFilled ? store.phaseProgress : 0), height: 6)
                        .animation(.spring(duration: 1.2, bounce: 0.05), value: progressFilled)
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                progressFilled = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isFreedom
            ? "Freedom phase. Day \(dayCount)."
            : "\(store.fastingPhase.rawValue) phase. \(store.timeToNextMilestone) to next milestone."
        )
    }
    // MARK: - All badges earned

    private var allBadgesEarnedRow: some View {
        let days = Int(store.elapsedSeconds / 86400)
        return HStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Color("NCSuccess"))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 3) {
                Text("All badges earned.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color("NCTextPrimary"))
                Text("\(days) days and counting. This is identity now.")
                    .font(.system(size: 11, weight: .light))
                    .foregroundStyle(Color("NCTextSecondary"))
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color("NCSurface"))
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("All badges earned. \(days) days and counting.")
    }

    // MARK: - Next unearned badge

    private var nextUnearnedBadge: BadgeID? {
        guard store.isTracking else { return nil }
        return BadgeID.allCases.first { !store.earnedBadges.contains($0) }
    }

    private func nextBadgeRow(_ badge: BadgeID) -> some View {
        let remaining = max(0, badge.threshold - store.elapsedSeconds)
        let progress  = min(1.0, store.elapsedSeconds / badge.threshold)

        let remainingText: String = {
            let h = Int(remaining) / 3600
            let m = (Int(remaining) % 3600) / 60
            if h >= 24 {
                let d = h / 24; let rh = h % 24
                return rh > 0 ? "\(d)d \(rh)h" : "\(d)d"
            }
            if h > 0 { return m > 0 ? "\(h)h \(m)m" : "\(h)h" }
            return "\(m)m"
        }()

        // Show the calendar date the badge unlocks when it's more than a day away —
        // "unlocks Thursday" is more grounding than "5d 3h".
        let unlockDateText: String? = {
            guard remaining > 86_400, let start = store.lastSugarDate else { return nil }
            let unlockDate = start.addingTimeInterval(badge.threshold)
            let days = Calendar.current.dateComponents([.day], from: Date(), to: unlockDate).day ?? 0
            let df = DateFormatter()
            df.dateFormat = days < 7 ? "EEEE" : "MMM d"   // "Thursday" vs "Nov 14"
            return "unlocks \(df.string(from: unlockDate))"
        }()

        let isCloseIn = progress >= 0.75
        return HStack(spacing: 12) {
            Image(systemName: badge.symbol)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(isCloseIn ? Color("NCSuccess").opacity(0.7) : Color("NCTextTertiary"))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(badge.label)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color("NCTextSecondary"))
                        if let dateText = unlockDateText {
                            Text(dateText)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(Color("NCTextTertiary").opacity(0.7))
                        }
                    }
                    Spacer()
                    Text(remaining < 120 ? "almost there" : (isCloseIn ? "closing in · \(remainingText)" : "\(remainingText) away"))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(isCloseIn ? Color("NCSuccess") : Color("NCTextTertiary"))
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color("NCTextTertiary").opacity(0.2))
                            .frame(height: 4)
                        Capsule()
                            .fill(isCloseIn ? Color("NCSuccess") : Color("NCSuccess").opacity(0.6))
                            .frame(width: geo.size.width * progress, height: 4)
                            .animation(.spring(duration: 0.8), value: progress)
                    }
                }
                .frame(height: 4)

                // Lookahead teaser — the anticipatory label that frames why
                // this milestone matters before it's reached.
                let teaser = badge.lookaheadText
                if !teaser.isEmpty {
                    Text(teaser)
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(Color("NCTextTertiary").opacity(0.65))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color("NCSurface"))
        .cornerRadius(10)
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
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(earned ? Color("NCTextPrimary") : Color("NCTextTertiary"))
                .multilineTextAlignment(.center)
                .frame(width: 60)
        }
        .accessibilityLabel(earned
            ? "\(badge.label) badge, earned. \(badge.celebrationText.components(separatedBy: "\n").first ?? "")"
            : "\(badge.label) badge, locked"
        )
        .accessibilityHint(earned ? "Opens badge details" : "Shows how to unlock")
    }
}

// MARK: - Badge Detail

struct BadgeDetailView: View {
    let badge: BadgeID
    @EnvironmentObject var store: FastingStore
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var shareImage: UIImage? = nil
    @State private var showShareSheet = false

    private var shareText: String {
        "\(badge.label) sugar-free. \(store.formattedElapsed) and counting.\n\n\(badge.celebrationText)\n\n— tracked with Nightcap"
    }

    private var reductionGrams: Int? {
        guard let quiz = appState.quizSugarGrams,
              let current = appState.dailySugarGrams,
              current < quiz else { return nil }
        return quiz - current
    }

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

                VStack(spacing: 12) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task { @MainActor in
                            let img = makeShareImage(
                                badge: badge,
                                elapsedSeconds: store.elapsedSeconds,
                                reductionGrams: reductionGrams
                            )
                            shareImage = img
                            showShareSheet = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .light))
                            Text("Share your progress")
                                .font(.system(size: 15, weight: .regular))
                        }
                        .foregroundStyle(Color("NCTextSecondary"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color("NCSurface"))
                        .cornerRadius(12)
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Text(badge.dismissText)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(Color("NCBackground"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color("NCAccent"))
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showShareSheet) {
            let items: [Any] = shareImage.map { [$0] } ?? [shareText]
            ShareSheet(items: items)
                .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Milestone Sheet (for in-app popups)

struct MilestoneSheet: View {
    let badge: BadgeID
    @EnvironmentObject var store: FastingStore
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @Environment(\.requestReview) private var requestReview
    @State private var shareImage: UIImage? = nil
    @State private var showShareSheet = false
    @State private var iconScaled = false

    private var shareText: String {
        "\(badge.label) sugar-free. \(store.formattedElapsed) and counting.\n\n\(badge.celebrationText)\n\n— tracked with Nightcap"
    }

    /// Grams reduced vs. original quiz estimate — shown on share card when meaningful.
    private var reductionGrams: Int? {
        guard let quiz = appState.quizSugarGrams,
              let current = appState.dailySugarGrams,
              current < quiz else { return nil }
        return quiz - current
    }

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
                .scaleEffect(iconScaled ? 1.0 : 0.2)
                .animation(.spring(duration: 0.7, bounce: 0.45), value: iconScaled)

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

                // Sugar avoided — shown for one-week+ milestones when number is set.
                if badge.threshold >= 604_800,
                   let g = appState.dailySugarGrams, g > 0 {
                    let days = Int(store.elapsedSeconds / 86400)
                    let avoided = days * g
                    let kg = Double(avoided) / 1000
                    let formatted = avoided >= 1_000
                        ? String(format: "~%.1fkg", kg)
                        : "~\(avoided)g"
                    Text("\(formatted) of added sugar not processed.")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Color("NCSuccess").opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                // Licensing effect — counter "I've earned a break" thinking at milestone moments.
                // Badge-specific so it doesn't feel generic on repeat milestone views.
                Text(badge.antiLicensingText)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color("NCTextTertiary").opacity(0.6))
                    .multilineTextAlignment(.center)

                Spacer()

                VStack(spacing: 12) {
                    // Share button
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task { @MainActor in
                            let img = makeShareImage(
                                badge: badge,
                                elapsedSeconds: store.elapsedSeconds,
                                reductionGrams: reductionGrams
                            )
                            // Prefer the rendered image; fall back to plain text if
                            // ImageRenderer fails (e.g. in the simulator without a display).
                            shareImage = img
                            showShareSheet = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .light))
                            Text("Share your progress")
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
                        Text(badge.dismissText)
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
            // Use the rendered image if available, otherwise share plain text.
            let items: [Any] = shareImage.map { [$0] } ?? [shareText]
            ShareSheet(items: items)
                .presentationDetents([.medium, .large])
        }
        .onAppear {
            // Spring entrance for badge icon
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                iconScaled = true
            }
            // Multi-step haptic: medium → heavy → success notification
            let medium = UIImpactFeedbackGenerator(style: .medium)
            let heavy  = UIImpactFeedbackGenerator(style: .heavy)
            medium.impactOccurred()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                heavy.impactOccurred()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            // Request a review at the 1-week and 1-month milestones.
            // Apple allows 3 prompts per year; each badge is earned at most once.
            if badge == .oneWeek || badge == .oneMonth {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    requestReview()
                }
            }
        }
    }
}

// MARK: - Locked Badge Sheet

struct LockedBadgeSheet: View {
    let badge: BadgeID
    @EnvironmentObject var store: FastingStore
    @Environment(\.dismiss) var dismiss

    private var remaining: TimeInterval {
        max(0, badge.threshold - store.elapsedSeconds)
    }

    /// Calendar date when this badge unlocks, shown when more than 1 day away.
    private var unlockDateLabel: String? {
        guard remaining > 86_400, let start = store.lastSugarDate else { return nil }
        let unlockDate = start.addingTimeInterval(badge.threshold)
        let days = Calendar.current.dateComponents([.day], from: Date(), to: unlockDate).day ?? 0
        let df = DateFormatter()
        df.dateFormat = days < 7 ? "EEEE" : "MMM d"
        return "unlocks \(df.string(from: unlockDate))"
    }

    private var remainingText: String {
        let secs = Int(remaining)
        let h = secs / 3600
        let m = (secs % 3600) / 60
        let d = h / 24
        if remaining < 120 { return "almost there" }
        if d >= 1 {
            let rh = h % 24
            return rh > 0 ? "\(d)d \(rh)h away" : "\(d)d away"
        }
        if h > 0  { return m > 0 ? "\(h)h \(m)m away" : "\(h)h away" }
        return "\(m)m away"
    }

    var body: some View {
        ZStack {
            Color("NCBackground").ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color("NCTextTertiary").opacity(0.08))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color("NCTextTertiary").opacity(0.2), lineWidth: 1)
                        )
                    Image(systemName: badge.symbol)
                        .font(.system(size: 40, weight: .light))
                        .foregroundStyle(Color("NCTextTertiary").opacity(0.5))
                }

                VStack(spacing: 8) {
                    Text(badge.label)
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(Color("NCTextPrimary"))
                    Text(remainingText)
                        .font(.system(size: 15, design: .monospaced))
                        .foregroundStyle(Color("NCTextTertiary"))
                    if store.isTracking {
                        Text("\(store.formattedElapsed) in.")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(Color("NCTextTertiary").opacity(0.7))
                    }
                    if let dateLabel = unlockDateLabel {
                        Text(dateLabel)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Color("NCTextTertiary").opacity(0.6))
                    }
                }

                Text(badge.lookaheadText)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text(badge.scienceFact)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color("NCTextTertiary"))
                    .lineSpacing(5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button { dismiss() } label: {
                    Text(badge.lockedDismissText)
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
        .accessibilityLabel("\(badge.label) badge, locked. \(remainingText).")
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
