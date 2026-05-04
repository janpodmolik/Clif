import Foundation
import ManagedSettings
import UserNotifications

/// Shield Action Extension - handles button taps on the shield.
///
/// IMPORTANT: There is no public API to open the host app from a ShieldActionExtension.
/// Instead, we schedule a local notification with a deep link the user can tap to return
/// to Uuumi. The notification is the only Apple-compliant bridge from shield to host.
class ShieldActionExtension: ShieldActionDelegate {

    // MARK: - Notification Scheduling

    private enum UnlockKind {
        case usage
        case dayStart

        var identifier: String {
            switch self {
            case .usage: "shield-unlock-usage"
            case .dayStart: "shield-unlock-daystart"
            }
        }

        var title: String {
            switch self {
            case .usage: String(localized: "Open Uuumi to unlock")
            case .dayStart: String(localized: "Open Uuumi to start your day")
            }
        }

        var body: String {
            switch self {
            case .usage: String(localized: "Tap to end your break")
            case .dayStart: String(localized: "Choose your daily preset")
            }
        }

        var deepLink: String {
            switch self {
            case .usage: DeepLinks.shield
            case .dayStart: DeepLinks.presetPicker
            }
        }
    }

    private func scheduleUnlockNotification(_ kind: UnlockKind) {
        let content = UNMutableNotificationContent()
        content.title = kind.title
        content.body = kind.body
        content.userInfo = ["deepLink": kind.deepLink]
        content.sound = nil

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(
            identifier: kind.identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                ExtensionLogger.log(
                    "Failed to schedule unlock notification: \(error.localizedDescription)",
                    prefix: "[ShieldAction]"
                )
            }
        }
    }

    private func logToFile(_ message: String) {
        ExtensionLogger.log(message, prefix: "[ShieldAction]")
    }

    // MARK: - Day Start Shield Handling

    private var isDayStartShield: Bool {
        SharedDefaults.isDayStartShieldActive
    }

    // MARK: - Unlock Handling

    /// Prepares unlock state and signals main app.
    /// Break handling is left to the main app when user taps the lock button.
    private func prepareUnlock() {
        logToFile("prepareUnlock() - preparing state")
        logToFile("Current state: wind=\(SharedDefaults.monitoredWindPoints), isShieldActive=\(SharedDefaults.isShieldActive)")

        SharedDefaults.pendingShieldUnlock = true

        logToFile("prepareUnlock() - done")
    }

    // MARK: - ShieldActionDelegate

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        logToFile("handle(action:for APPLICATION) - action=\(action == .primaryButtonPressed ? "primary" : "secondary")")
        logToFile("Current state: wind=\(SharedDefaults.monitoredWindPoints), isShieldActive=\(SharedDefaults.isShieldActive), isDayStart=\(SharedDefaults.isDayStartShieldActive)")

        if isDayStartShield {
            logToFile("Handled as Day Start Shield -> .close + notification")
            scheduleUnlockNotification(.dayStart)
            completionHandler(.close)
            return
        }

        switch action {
        case .primaryButtonPressed:
            logToFile("Primary button (Unlock) pressed - scheduling notification")
            prepareUnlock()
            scheduleUnlockNotification(.usage)
            completionHandler(.close)

        case .secondaryButtonPressed:
            logToFile("Secondary button (Close) pressed")
            completionHandler(.close)

        @unknown default:
            logToFile("Unknown action - closing shield")
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        logToFile("handle(action:for WEB DOMAIN) - action=\(action == .primaryButtonPressed ? "primary" : "secondary")")

        if isDayStartShield {
            logToFile("Handled as Day Start Shield -> .close + notification")
            scheduleUnlockNotification(.dayStart)
            completionHandler(.close)
            return
        }

        switch action {
        case .primaryButtonPressed:
            logToFile("Unlock pressed - scheduling notification")
            prepareUnlock()
            scheduleUnlockNotification(.usage)
            completionHandler(.close)

        case .secondaryButtonPressed:
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        logToFile("handle(action:for CATEGORY) - action=\(action == .primaryButtonPressed ? "primary" : "secondary")")

        if isDayStartShield {
            logToFile("Handled as Day Start Shield -> .close + notification")
            scheduleUnlockNotification(.dayStart)
            completionHandler(.close)
            return
        }

        switch action {
        case .primaryButtonPressed:
            logToFile("Unlock pressed - scheduling notification")
            prepareUnlock()
            scheduleUnlockNotification(.usage)
            completionHandler(.close)

        case .secondaryButtonPressed:
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }
}
