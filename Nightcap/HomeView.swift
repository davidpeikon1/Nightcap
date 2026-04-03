import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: FastingStore
    @EnvironmentObject var appState: AppState

    /// When true, the view is rendered behind onboarding coachmarks — disable interaction.
    var coachmarkMode: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            Color("NCBackground").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Top bar
                    topBar
                        .padding(.top, 56)

                    // Weekly insight (conditional — appears above tracker)
                    WeeklyInsightCard()

                    // Feature 1: Fast tracker
                    FastTrackerCard()

                    // Feature 2: Daily reframe
                    DailyReframeCard()

                    // Progress & badges
                    ProgressSection()

                    // Feature 3: Craving toolkit
                    CravingToolkitSection()

                    Spacer(minLength: 60)
                }
                .padding(.horizontal, 24)
            }
        }
        .allowsHitTesting(!coachmarkMode)
        // Badge milestone sheet
        .sheet(item: badgeBinding) { badge in
            MilestoneSheet(badge: badge)
                .presentationDetents([.medium])
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

            if store.streakDays > 0 {
                streakBadge
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

    // MARK: - Badge binding

    private var badgeBinding: Binding<BadgeID?> {
        Binding(
            get: { store.newlyUnlockedBadge },
            set: { _ in store.dismissBadge() }
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
