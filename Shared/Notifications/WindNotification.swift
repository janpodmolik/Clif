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

    /// All notifications are configurable in settings.
    static var configurableNotifications: [WindNotification] {
        allCases
    }

    var percentage: Int { rawValue }

    var title: String {
        switch self {
        case .light: return "🍃"
        case .strong: return "💨"
        case .critical: return "🌪️"
        }
    }

    var body: String {
        switch self {
        case .light:
            return "Hele, začíná tu foukat... ale tak aspoň nebude horko!"
        case .strong:
            return "Tohle už je pořádnej vítr. Nešlo by s tím něco dělat?"
        case .critical:
            return "HALOOO?! Začíná to tu bejt dost nebezpečný, pomoc prosím!"
        }
    }

    var settingsTitle: String {
        switch self {
        case .light: return "Lehký vítr (25%)"
        case .strong: return "Silný vítr (60%)"
        case .critical: return "Kritický vítr (85%)"
        }
    }

    var settingsPreview: String {
        return "\"\(body.prefix(40))...\""
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
