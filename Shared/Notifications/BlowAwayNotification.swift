import UserNotifications

/// Shared notification helper for blow away events.
/// Used by both DeviceActivityMonitor and ShieldAction extensions.
enum BlowAwayNotification {

    /// Sends a notification that the pet has been blown away.
    /// - Parameter logHandler: Optional closure for logging (extensions use different loggers)
    static func send(logHandler: ((String) -> Void)? = nil) {
        logHandler?("[Notification] Sending: blowAway")

        let content = UNMutableNotificationContent()
        content.title = "Mazlíček odfouknut! 💨"
        content.body = "Tvůj mazlíček byl odfouknut větrem. Otevři Clif a podívej se co se stalo."
        content.sound = .default
        content.userInfo = ["deepLink": DeepLinks.home]
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "blowAway_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                logHandler?("[Notification] FAILED: blowAway - \(error.localizedDescription)")
            } else {
                logHandler?("[Notification] SUCCESS: blowAway")
            }
        }
    }
}
