import SwiftUI

@main
struct NightcapApp: App {
    @StateObject private var fastingStore = FastingStore()
    @StateObject private var appState    = AppState()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(fastingStore)
                .environmentObject(appState)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var fastingStore: FastingStore

    var body: some View {
        Group {
            if appState.isOnboardingComplete {
                HomeView()
            } else {
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.isOnboardingComplete)
    }
}
