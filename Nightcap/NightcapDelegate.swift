import UIKit
import UserNotifications

// MARK: - Notification names for shortcut → SwiftUI bridge

extension Notification.Name {
    static let nightcapOpenResetModal     = Notification.Name("nightcap.openResetModal")
    static let nightcapOpenCravingToolkit = Notification.Name("nightcap.openCravingToolkit")
    static let nightcapOpenHistory        = Notification.Name("nightcap.openHistory")
}

// MARK: - UIApplicationDelegate

class NightcapDelegate: NSObject, UIApplicationDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Receive notification tap events so we can deep-link from tapped notifications.
        UNUserNotificationCenter.current().delegate = self

        registerShortcutItems(for: application)

        // App launched directly from a shortcut (was not running).
        // Post the notification after a short delay so SwiftUI views are ready.
        if let item = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.handle(item)
            }
        }
        return true
    }

    // App resumed from background via a shortcut.
    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        handle(shortcutItem)
        completionHandler(true)
    }

    // MARK: - Private

    private func registerShortcutItems(for application: UIApplication) {
        application.shortcutItems = [
            UIApplicationShortcutItem(
                type: "com.nightcap.app.logReset",
                localizedTitle: "Log a Reset",
                localizedSubtitle: "Log it as data",
                icon: UIApplicationShortcutIcon(systemImageName: "arrow.counterclockwise")
            ),
            UIApplicationShortcutItem(
                type: "com.nightcap.app.craving",
                localizedTitle: "Having a Craving?",
                localizedSubtitle: "Open the craving toolkit",
                icon: UIApplicationShortcutIcon(systemImageName: "bolt")
            ),
        ]
    }

    private func handle(_ item: UIApplicationShortcutItem) {
        switch item.type {
        case "com.nightcap.app.logReset":
            NotificationCenter.default.post(name: .nightcapOpenResetModal, object: nil)
        case "com.nightcap.app.craving":
            NotificationCenter.default.post(name: .nightcapOpenCravingToolkit, object: nil)
        default:
            break
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NightcapDelegate: UNUserNotificationCenterDelegate {

    /// Called while the app is in the foreground and a notification is about to be
    /// delivered. Suppress in-app milestone banners — the MilestoneSheet already
    /// handles those. Show streak, PB, morning, evening, and personalized banners
    /// even while in-app so users who open the app right after crossing a threshold
    /// still receive the feedback.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let id = notification.request.identifier
        // Milestone sheets are shown in-app via FastingStore.newlyUnlockedBadge —
        // suppress the redundant banner for those identifiers only.
        if id.hasPrefix("nightcap.milestone") {
            completionHandler([])
        } else {
            completionHandler([.banner, .sound])
        }
    }

    /// Called when the user taps a delivered notification.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier
        // Evening check-in notifications → open craving toolkit.
        // Identifiers follow "nightcap.evening.dN" (day-offset) or legacy "nightcap.evening.wdN";
        // hasPrefix covers both. Delay so SwiftUI views are mounted before receiving the notification.
        if id.hasPrefix("nightcap.evening") || id.hasPrefix("nightcap.personalized") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .nightcapOpenCravingToolkit, object: nil)
            }
        }
        // Milestone and streak notifications → open history view so users see their progress.
        else if id.hasPrefix("nightcap.milestone") || id.hasPrefix("nightcap.streak") ||
                id.hasPrefix("nightcap.pb") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .nightcapOpenHistory, object: nil)
            }
        }
        completionHandler()
    }
}
