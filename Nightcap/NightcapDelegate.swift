import UIKit
import UserNotifications

// MARK: - Notification names for shortcut → SwiftUI bridge

extension Notification.Name {
    static let nightcapOpenResetModal    = Notification.Name("nightcap.openResetModal")
    static let nightcapOpenCravingToolkit = Notification.Name("nightcap.openCravingToolkit")
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

    /// Called when the user taps a delivered notification.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier
        // Evening check-in → open craving toolkit.
        // Delay so SwiftUI views are mounted before receiving the notification.
        if id == "nightcap.evening" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: .nightcapOpenCravingToolkit, object: nil)
            }
        }
        completionHandler()
    }
}
