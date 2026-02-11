import Foundation
import UserNotifications

/// Wind reminder notification — sent 30 minutes after wind stays high (≥50%) with no active break.
/// Reminds the user to start a break so wind can decrease.
enum WindReminderNotification {

    /// Delay before notification fires.
    #if DEBUG
    static let delay: TimeInterval = 30 // 30s for testing
    #else
    static let delay: TimeInterval = 30 * 60
    #endif

    /// Wind percentage at which reminder gets scheduled.
    static let windThreshold: Double = 50

    /// Fixed identifier — scheduling always replaces previous pending reminder.
    private static let identifier = "wind_reminder_scheduled"

    static var title: String { "Vítr stále fouká" }

    static var body: String {
        "Tvůj mazlíček je pořád ve větru. Zapni pauzu a nech ho vydechnout!"
    }

    // MARK: - Scheduling

    /// Schedules reminder notification 30 minutes from now.
    /// Uses a fixed identifier, so calling this again replaces any existing pending reminder.
    static func schedule(logHandler: ((String) -> Void)? = nil) {
        logHandler?("[Notification] Scheduling wind reminder in \(Int(delay))s")

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["deepLink": DeepLinks.home]
        content.interruptionLevel = .timeSensitive

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                logHandler?("[Notification] FAILED to schedule wind reminder: \(error.localizedDescription)")
            } else {
                logHandler?("[Notification] SUCCESS: wind reminder scheduled")
            }
        }
    }

    /// Cancels any pending wind reminder notification.
    static func cancel(logHandler: ((String) -> Void)? = nil) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
        logHandler?("[Notification] Cancelled wind reminder")
    }
}
