import Foundation

/// Granular notification preferences.
/// Stored as part of `LimitSettings` in SharedDefaults (App Group).
struct NotificationSettings: Codable, Equatable {

    // MARK: - Master Toggle

    /// When false, all notifications are suppressed.
    var masterEnabled: Bool = true

    // MARK: - Wind Notifications (per-threshold)

    var windLight: Bool = true       // 25%
    var windStrong: Bool = true      // 60%
    var windCritical: Bool = true    // 85%

    // MARK: - Break Notifications

    var breakCommittedEnded: Bool = true
    /// Covers both free break and safety break wind-zero notifications.
    var breakWindZero: Bool = true

    // MARK: - Summaries & Reminders

    var dailySummary: Bool = true
    var evolutionReady: Bool = true

    // MARK: - Defaults

    static let `default` = NotificationSettings()

    // MARK: - Queries

    func shouldSendWind(_ notification: WindNotification) -> Bool {
        guard masterEnabled else { return false }
        switch notification {
        case .light: return windLight
        case .strong: return windStrong
        case .critical: return windCritical
        }
    }

    func shouldSendBreak(_ notification: BreakNotification) -> Bool {
        guard masterEnabled else { return false }
        switch notification {
        case .committedBreakEnded: return breakCommittedEnded
        case .freeBreakWindZero, .safetyBreakWindZero: return breakWindZero
        }
    }

    // MARK: - Migration

    static func migrated(from mode: NotificationMode) -> NotificationSettings {
        var settings = NotificationSettings()
        switch mode {
        case .off:
            settings.windLight = false
            settings.windStrong = false
            settings.windCritical = false
        case .important:
            settings.windLight = false
            settings.windStrong = false
            settings.windCritical = true
        case .all:
            break // all true by default
        }
        return settings
    }
}
