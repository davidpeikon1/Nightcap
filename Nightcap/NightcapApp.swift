import SwiftUI
import AppIntents
import WidgetKit

@main
struct NightcapApp: App {
    @UIApplicationDelegateAdaptor(NightcapDelegate.self) var delegate
    @StateObject private var fastingStore = FastingStore()
    @StateObject private var appState    = AppState()
    @Environment(\.scenePhase) private var scenePhase

    init() {
        NightcapShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(fastingStore)
                .environmentObject(appState)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                WidgetCenter.shared.reloadAllTimelines()
            } else if phase == .active {
                fastingStore.syncBadgeCount()
                // Re-schedule daily notifications on each foreground so the
                // 14-day day-offset window stays current.
                NotificationManager.shared.checkAuthorizationStatus { status in
                    if status == .authorized {
                        NotificationManager.shared.scheduleDailyNotifications()
                    }
                }
                // Write the current daily quote to the App Group so the widget
                // can display it without needing direct access to QuoteLibrary.
                let quote = QuoteLibrary.dailyQuote(for: fastingStore.elapsedSeconds)
                UserDefaults(suiteName: "group.com.nightcap.app")?
                    .set(quote.text, forKey: "currentQuoteText")
                // Refresh personalized notification window (reschedules the 14-day
                // block so the correct days stay covered as time advances).
                if fastingStore.cravingLogs.count >= 5 {
                    fastingStore.schedulePersonalizedCravingNotification()
                }
            }
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
