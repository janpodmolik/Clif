import Foundation
import UserNotifications

/// Break-related notifications.
/// - Committed break: scheduled notification when timer runs out.
/// - Free break: notification when wind drops to 0% during the break.
enum BreakNotification {

    /// Committed break completed successfully - time's up.
    case committedBreakEnded

    /// Wind dropped to 0% during a free break - break goal achieved.
    case freeBreakWindZero

    /// Wind dropped to 0% during a safety break - safe to unlock.
    case safetyBreakWindZero

    var title: String {
        switch self {
        case .committedBreakEnded:
            return "Break skončil"
        case .freeBreakWindZero:
            return "Vítr ustal"
        case .safetyBreakWindZero:
            return "Vítr ustal"
        }
    }

    var body: String {
        switch self {
        case .committedBreakEnded:
            return "Tvůj committed break skončil! Pauza byla úspěšná."
        case .freeBreakWindZero:
            return "Vítr úplně ustal – tvůj mazlíček je v bezpečí!"
        case .safetyBreakWindZero:
            return "Vítr ustal – můžeš bezpečně odemknout telefon."
        }
    }

    private var identifier: String {
        switch self {
        case .committedBreakEnded:
            return "break_committed_ended"
        case .freeBreakWindZero:
            return "break_free_wind_zero"
        case .safetyBreakWindZero:
            return "break_safety_wind_zero"
        }
    }

    // MARK: - Sending

    /// Sends this notification immediately.
    func send() {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["deepLink": DeepLinks.home]
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "\(identifier)_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error = error {
                print("[BreakNotification] FAILED: \(self.identifier) - \(error.localizedDescription)")
            } else {
                print("[BreakNotification] SUCCESS: \(self.identifier)")
            }
            #endif
        }
    }

    // MARK: - Scheduled Committed Break End

    /// Schedules the committed break end notification for a future date.
    /// - Parameter fireDate: When the notification should fire.
    static func scheduleCommittedBreakEnd(at fireDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = BreakNotification.committedBreakEnded.title
        content.body = BreakNotification.committedBreakEnded.body
        content.sound = .default
        content.userInfo = ["deepLink": DeepLinks.home]
        content.interruptionLevel = .timeSensitive

        let interval = fireDate.timeIntervalSinceNow
        guard interval > 0 else {
            // Already past - send immediately
            BreakNotification.committedBreakEnded.send()
            return
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: "break_committed_ended_scheduled",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            #if DEBUG
            if let error = error {
                print("[BreakNotification] Schedule FAILED: \(error.localizedDescription)")
            } else {
                print("[BreakNotification] Scheduled committed break end in \(String(format: "%.0f", interval))s")
            }
            #endif
        }
    }

    /// Cancels any scheduled committed break end notification.
    static func cancelScheduledCommittedBreakEnd() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["break_committed_ended_scheduled"]
        )
        #if DEBUG
        print("[BreakNotification] Cancelled scheduled committed break end notification")
        #endif
    }
}
