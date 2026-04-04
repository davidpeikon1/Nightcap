import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject var store: FastingStore
    @EnvironmentObject var appState: AppState

    /// When true the view is rendered under onboarding coachmarks — disable interaction.
    var coachmarkMode: Bool = false

    @State private var showSettings      = false
    @State private var showQuickReset    = false
    @State private var showHistory       = false
    @State private var showPhaseDetail: FastingPhase? = nil
    @State private var flamePulse: CGFloat = 1.0

    var body: some View {
        ZStack(alignment: .top) {
            Color("NCBackground").ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        topBar
                            .padding(.top, 56)

                        // Hero card: quote first, timer below — both visible on open
                        HeroCard()

                        // Weekly insight (only when there's enough data)
                        WeeklyInsightCard()

                        // Body science (collapsed by default, tap to expand)
                        BodyScienceCard()

                        // Progress + badges
                        ProgressSection()

                        // Feature 3 — Craving toolkit
                        CravingToolkitSection()
                            .id("cravingToolkit")

                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 24)
                }
                .onReceive(NotificationCenter.default.publisher(for: .nightcapOpenCravingToolkit)) { _ in
                    guard !coachmarkMode else { return }
                    // Delay slightly so the expand animation starts first, then scroll.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(duration: 0.5)) {
                            proxy.scrollTo("cravingToolkit", anchor: .top)
                        }
                    }
                }
            }

            // Phase-unlock toast — floats above scroll content, tappable for details
            if let phase = store.phaseJustUnlocked {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    store.phaseJustUnlocked = nil   // dismiss immediately so it can't re-appear after sheet closes
                    showPhaseDetail = phase
                } label: {
                    PhaseUnlockToast(phase: phase)
                }
                .buttonStyle(.plain)
                .padding(.top, 56)
                .padding(.horizontal, 24)
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(10)
            }
        }
        .allowsHitTesting(!coachmarkMode)
        .animation(.spring(duration: 0.5), value: store.phaseJustUnlocked)
        // Badge milestone sheet
        .sheet(item: Binding(
            get: { store.newlyUnlockedBadge },
            set: { _ in store.dismissBadge() }
        )) { badge in
            MilestoneSheet(badge: badge)
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showHistory) {
            FastHistoryView()
        }
        .sheet(isPresented: $showQuickReset) {
            ResetModal()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $showPhaseDetail) { phase in
            PhaseDetailSheet(phase: phase)
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .onReceive(NotificationCenter.default.publisher(for: .nightcapOpenResetModal)) { _ in
            // Only open the reset modal when a fast is actually in progress;
            // firing this with nothing tracked would log a 0-second reset entry.
            guard !coachmarkMode, store.isTracking else { return }
            showQuickReset = true
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(alignment: .center) {
            Text("nightcap")
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(Color("NCTextPrimary"))
                .tracking(-0.5)

            Spacer()

            HStack(spacing: 12) {
                if store.streakDays > 0 {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showHistory = true
                    } label: { streakBadge }
                        .buttonStyle(.plain)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                }
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(Color("NCTextSecondary"))
                }
            }
            .animation(.spring(duration: 0.4), value: store.streakDays > 0)
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color("NCWarning"))
                .scaleEffect(flamePulse)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.4)
                        .repeatForever(autoreverses: true)
                        .delay(0.5)
                    ) {
                        flamePulse = 1.18
                    }
                }
            Text("\(store.streakDays) day\(store.streakDays == 1 ? "" : "s")")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color("NCTextPrimary"))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color("NCSurface"))
        .cornerRadius(8)
    }
}

// MARK: - Phase Unlock Toast

struct PhaseUnlockToast: View {
    let phase: FastingPhase

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "arrow.up.circle")
                .font(.system(size: 18, weight: .light))
                .foregroundStyle(Color("NCSuccess"))

            VStack(alignment: .leading, spacing: 2) {
                Text("entering")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color("NCTextSecondary"))
                Text(phase.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color("NCTextPrimary"))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(phase.tagline)
                    .font(.system(size: 12, weight: .light))
                    .foregroundStyle(Color("NCTextSecondary"))
                    .multilineTextAlignment(.trailing)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .light))
                    .foregroundStyle(Color("NCTextTertiary").opacity(0.6))
            }
            .frame(maxWidth: 110)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("NCSurface"))
                .shadow(color: Color("NCTextPrimary").opacity(0.08), radius: 12, y: 4)
        )
        .accessibilityLabel("Entering \(phase.rawValue) phase. \(phase.tagline).")
        .accessibilityHint("Opens the phase detail view")
    }
}

// MARK: - Preview

#Preview {
    let store = FastingStore()
    let state = AppState()
    return HomeView()
        .environmentObject(store)
        .environmentObject(state)
}
