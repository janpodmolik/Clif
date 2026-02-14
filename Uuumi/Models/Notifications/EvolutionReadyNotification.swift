import Foundation
import UserNotifications

/// Evolution ready notification — one-shot scheduled at the random unlock time.
/// Re-evaluated on each foreground return.
enum EvolutionReadyNotification {

    static let identifier = "evolution_ready_scheduled"

    static var title: String { "Evoluce připravena!" }

    static var body: String {
        "Tvůj Uuumi je připraven evolvovat. Nenech ho čekat!"
    }

    // MARK: - Scheduling

    /// Schedules a one-shot notification at a specific date (used for random unlock times).
    /// Uses a fixed identifier, so calling again replaces any existing.
    static func scheduleAt(_ date: Date) {
        guard date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["deepLink": DeepLinks.home]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
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
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm:ss"
                print("[EvolutionReadyNotification] Scheduled at \(formatter.string(from: date))")
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
