import Foundation
import UserNotifications

/// Come-back nudges for lapsed users — scheduled on every background transition,
/// cancelled on foreground return, so they only fire after real absence.
/// Without these the app goes permanently silent once a user stops opening it:
/// every other notification requires same-day activity.
enum ReEngagementNotification {

    private static let firstIdentifier = "re_engagement_first"
    private static let secondIdentifier = "re_engagement_second"
    private static let identifiers = [firstIdentifier, secondIdentifier]

    /// Replaces any pending nudges with fresh ones measured from now.
    /// With a living pet: +2 and +5 days. Without one (blown away / archived /
    /// deleted): a single +1 day invitation to start over.
    static func scheduleOnBackground(livingPetName: String?) {
        cancel()
        guard SharedDefaults.limitSettings.notifications.shouldSendReEngagement() else { return }

        if let petName = livingPetName {
            schedule(
                identifier: firstIdentifier,
                afterDays: 2,
                title: String(localized: "\(petName) misses you"),
                body: String(localized: "The wind is calm today. A perfect moment to visit your island.")
            )
            schedule(
                identifier: secondIdentifier,
                afterDays: 5,
                title: String(localized: "\(petName) is still waiting"),
                body: String(localized: "Your island is quiet without you. One small visit keeps the journey going.")
            )
        } else {
            schedule(
                identifier: firstIdentifier,
                afterDays: 1,
                title: String(localized: "A new companion awaits"),
                body: String(localized: "Your island is ready for a fresh start. Meet your next Uuumi today.")
            )
        }
    }

    private static func schedule(identifier: String, afterDays days: Int, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["deepLink": DeepLinks.home]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(days) * 24 * 60 * 60,
            repeats: false
        )
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Cancels pending nudges — called on foreground return.
    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}
