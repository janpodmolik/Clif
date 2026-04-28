import Foundation
import UserNotifications

/// Wind reminder notification — sent 5 minutes after wind is active (>0%) with no active break.
/// Reminds the user to start a break so wind can decrease.
enum WindReminderNotification {

    /// Delay before notification fires.
    #if DEBUG
    static let delay: TimeInterval = 30 // 30s for testing
    #else
    static let delay: TimeInterval = 5 * 60
    #endif

    /// Fixed identifier — scheduling always replaces previous pending reminder.
    private static let identifier = "wind_reminder_scheduled"

    static var title: String {
        [
            String(localized: "Wind is still blowing"),
            String(localized: "Still windy out here"),
            String(localized: "Wind hasn't given up"),
            String(localized: "It's still rough"),
            String(localized: "Anybody home?"),
        ].randomElement()!
    }

    static var body: String {
        [
            String(localized: "Your pet is still in the wind. Start a break and let it breathe!"),
            String(localized: "Still getting blown around. A break would really help right now."),
            String(localized: "The wind didn't go anywhere. Mind taking a break?"),
            String(localized: "Pet's holding on but tired. One break would calm things down."),
            String(localized: "Hello? Wind's still happening. Break, please?"),
        ].randomElement()!
    }

    // MARK: - Scheduling

    /// Schedules reminder notification 5 minutes from now.
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
