import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: FastingStore
    @EnvironmentObject var appState: AppState

    /// When true the view is rendered under onboarding coachmarks — disable interaction.
    var coachmarkMode: Bool = false

    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .top) {
            Color("NCBackground").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    topBar
                        .padding(.top, 56)

                    // Weekly insight (only when there's enough data)
                    WeeklyInsightCard()

                    // Feature 1 — Fast tracker
                    FastTrackerCard()

                    // Feature 2 — Daily reframe
                    DailyReframeCard()

                    // Body science (collapsed by default, tap to expand)
                    BodyScienceCard()

                    // Progress + badges
                    ProgressSection()

                    // Feature 3 — Craving toolkit
                    CravingToolkitSection()

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 24)
            }

            // Phase-unlock toast — floats above scroll content
            if let phase = store.phaseJustUnlocked {
                PhaseUnlockToast(phase: phase)
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
                    streakBadge
                }
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(Color("NCTextSecondary"))
                }
            }
        }
    }

    private var streakBadge: some View {
        HStack(spacing: 5) {
            Image(systemName: "flame")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color("NCWarning"))
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
                Text("New phase unlocked")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color("NCTextSecondary"))
                Text(phase.rawValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color("NCTextPrimary"))
            }

            Spacer()

            Text(phase.tagline)
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color("NCTextSecondary"))
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 110)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("NCSurface"))
                .shadow(color: Color("NCTextPrimary").opacity(0.08), radius: 12, y: 4)
        )
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
