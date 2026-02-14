import Foundation
import UserNotifications

/// Daily summary notification — scheduled at user-configured evening time.
/// Shows motivational text; tapping opens DayDetailSheet for today via deep link.
enum DailySummaryNotification {

    private static let identifier = "daily_summary_scheduled"

    static var title: String { "Denní souhrn" }

    static var body: String {
        "Jak ti to dneska šlo? Koukni se na svůj denní přehled!"
    }

    // MARK: - Scheduling

    /// Schedules a repeating daily notification at the given hour/minute.
    /// Uses a fixed identifier, so calling again replaces any existing.
    static func schedule(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["deepLink": DeepLinks.dailySummary]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error = error {
                print("[DailySummaryNotification] Schedule FAILED: \(error.localizedDescription)")
            } else {
                print("[DailySummaryNotification] Scheduled at \(hour):\(String(format: "%02d", minute))")
            }
            #endif
        }
    }

    /// Cancels any pending daily summary notification.
    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
        #if DEBUG
        print("[DailySummaryNotification] Cancelled")
        #endif
    }
}
