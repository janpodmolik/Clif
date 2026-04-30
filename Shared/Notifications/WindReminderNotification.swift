import Foundation
import UserNotifications

/// Wind reminder notification — sent 5 minutes after wind reaches `triggerThreshold` with no active break.
/// Reminds the user to start a break so wind can decrease.
enum WindReminderNotification {

    /// Wind percentage at or above which a reminder is scheduled. Below this value any pending
    /// reminder is cancelled and the once-per-session debounce flag is reset.
    static let triggerThreshold: Double = 15

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
            String(localized: "A little breeze lingering"),
            String(localized: "Wind's still around"),
            String(localized: "Pet feels a draft"),
            String(localized: "Bit of wind hanging on"),
            String(localized: "Wind hasn't cleared"),
        ].randomElement()!
    }

    static var body: String {
        [
            String(localized: "Wind is sitting above zero. A break would bring it down."),
            String(localized: "Pet's doing fine, but the wind won't clear on its own."),
            String(localized: "Wind isn't going anywhere by itself. A short break clears it."),
            String(localized: "Wind's hanging above zero. How about a break?"),
            String(localized: "Pet's managing, but the breeze is sticking around."),
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
