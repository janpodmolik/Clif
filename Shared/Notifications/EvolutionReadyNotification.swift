import Foundation
import UserNotifications

/// Evolution ready notification — one-shot scheduled for the next occurrence of the configured time.
/// Only scheduled when pet can evolve and hasn't evolved today.
/// Re-evaluated on each foreground return.
enum EvolutionReadyNotification {

    private static let identifier = "evolution_ready_scheduled"

    static var title: String { "Evoluce připravena!" }

    static var body: String {
        "Tvůj Uuumi je připraven evolvovat. Nenech ho čekat!"
    }

    // MARK: - Scheduling

    /// Schedules a one-shot notification for the next occurrence of hour:minute.
    /// If that time has already passed today, iOS schedules for tomorrow.
    /// Uses a fixed identifier, so calling again replaces any existing.
    static func scheduleNext(hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["deepLink": DeepLinks.home]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error = error {
                print("[EvolutionReadyNotification] Schedule FAILED: \(error.localizedDescription)")
            } else {
                print("[EvolutionReadyNotification] Scheduled next at \(hour):\(String(format: "%02d", minute))")
            }
            #endif
        }
    }

    /// Cancels any pending evolution ready notification.
    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
        #if DEBUG
        print("[EvolutionReadyNotification] Cancelled")
        #endif
    }
}
