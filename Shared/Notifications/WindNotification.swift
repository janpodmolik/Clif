import SwiftUI
import UserNotifications

/// Wind warning notification thresholds and messages.
/// Sent when wind reaches specific percentages during app usage.
enum WindNotification: Int, CaseIterable, Codable, Hashable {
    case light = 25
    case strong = 60
    case critical = 85

    /// All threshold values as percentages.
    static let thresholds: [Int] = allCases.map(\.rawValue)

    var percentage: Int { rawValue }

    var title: String {
        switch self {
        case .light:
            return [
                String(localized: "Light wind"),
                String(localized: "Breeze picking up"),
                String(localized: "A little gust"),
                String(localized: "Wind says hi"),
                String(localized: "Things are moving"),
            ].randomElement()!
        case .strong:
            return [
                String(localized: "Strong wind"),
                String(localized: "This is getting rough"),
                String(localized: "Holding on tight"),
                String(localized: "Wind is serious now"),
                String(localized: "Storm warning"),
            ].randomElement()!
        case .critical:
            return [
                String(localized: "Critical wind"),
                String(localized: "About to blow away"),
                String(localized: "Mayday mayday"),
                String(localized: "Code red"),
                String(localized: "I can't hold on"),
            ].randomElement()!
        }
    }

    var body: String {
        switch self {
        case .light:
            return [
                String(localized: "Hey, it's getting windy... but at least it won't be hot!"),
                String(localized: "Felt a little gust here. Nothing dramatic yet."),
                String(localized: "Wind just rolled in. Still cozy though."),
                String(localized: "Just a heads-up — breeze is starting up."),
                String(localized: "The island's getting a bit drafty over here."),
            ].randomElement()!
        case .strong:
            return [
                String(localized: "This is some serious wind. Can we do something about it?"),
                String(localized: "Okay, this is no longer cute. Take a break?"),
                String(localized: "Getting tossed around a bit out here. Help?"),
                String(localized: "The wind is loud and I am small. Please."),
                String(localized: "Holding on with everything I've got."),
            ].randomElement()!
        case .critical:
            return [
                String(localized: "HELLOOO?! It's getting really dangerous here, help please!"),
                String(localized: "I'M ABOUT TO FLY AWAY. Please put the phone down!"),
                String(localized: "This is bad. This is really bad. Break time?!"),
                String(localized: "If you're reading this, I'm one gust from gone."),
                String(localized: "Last warning before liftoff. Save me!"),
            ].randomElement()!
        }
    }

    var color: Color {
        switch self {
        case .light: return .green
        case .strong: return .orange
        case .critical: return .red
        }
    }

    // MARK: - Sending

    /// Sends this wind notification.
    /// - Parameter logHandler: Optional closure for logging (extensions use different loggers)
    func send(logHandler: ((String) -> Void)? = nil) {
        logHandler?("[Notification] Sending: wind_\(percentage)%")

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["deepLink": DeepLinks.home]
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "wind_\(percentage)_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                logHandler?("[Notification] FAILED: wind_\(self.percentage)% - \(error.localizedDescription)")
            } else {
                logHandler?("[Notification] SUCCESS: wind_\(self.percentage)%")
            }
        }
    }

    /// Returns the highest notification threshold that was crossed.
    /// - Parameters:
    ///   - oldWind: Previous wind percentage
    ///   - newWind: New wind percentage
    /// - Returns: The highest crossed notification, or nil if no threshold was crossed
    ///
    /// Example: oldWind=20, newWind=70 → returns .strong (60%), not .light (25%)
    static func notificationFor(oldWind: Double, newWind: Double) -> WindNotification? {
        // Iterate in reverse (highest first: 85, 60, 25)
        for notification in allCases.reversed() {
            let threshold = Double(notification.percentage)
            if oldWind < threshold && newWind >= threshold {
                return notification
            }
        }
        return nil
    }
}
