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

    /// Whether any wind threshold notification is enabled.
    var anyWindEnabled: Bool {
        windLight || windStrong || windCritical
    }

    // MARK: - Break Notifications

    var breakCommittedEnded: Bool = true
    /// Covers both free break and safety break wind-zero notifications.
    var breakWindZero: Bool = true

    // MARK: - Wind Reminder

    /// Reminder when wind stays high (≥50%) for 30 min without a break.
    var windReminder: Bool = true

    // MARK: - Summaries & Reminders

    var dailySummary: Bool = true
    var evolutionReady: Bool = true

    // MARK: - Schedule Times

    var dailySummaryHour: Int = 20
    var dailySummaryMinute: Int = 0
    var evolutionReadyHour: Int = 8
    var evolutionReadyMinute: Int = 0

    // MARK: - Codable

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        masterEnabled = try container.decodeIfPresent(Bool.self, forKey: .masterEnabled) ?? true
        windLight = try container.decodeIfPresent(Bool.self, forKey: .windLight) ?? true
        windStrong = try container.decodeIfPresent(Bool.self, forKey: .windStrong) ?? true
        windCritical = try container.decodeIfPresent(Bool.self, forKey: .windCritical) ?? true
        breakCommittedEnded = try container.decodeIfPresent(Bool.self, forKey: .breakCommittedEnded) ?? true
        breakWindZero = try container.decodeIfPresent(Bool.self, forKey: .breakWindZero) ?? true
        windReminder = try container.decodeIfPresent(Bool.self, forKey: .windReminder) ?? true
        dailySummary = try container.decodeIfPresent(Bool.self, forKey: .dailySummary) ?? true
        evolutionReady = try container.decodeIfPresent(Bool.self, forKey: .evolutionReady) ?? true
        dailySummaryHour = try container.decodeIfPresent(Int.self, forKey: .dailySummaryHour) ?? 20
        dailySummaryMinute = try container.decodeIfPresent(Int.self, forKey: .dailySummaryMinute) ?? 0
        evolutionReadyHour = try container.decodeIfPresent(Int.self, forKey: .evolutionReadyHour) ?? 8
        evolutionReadyMinute = try container.decodeIfPresent(Int.self, forKey: .evolutionReadyMinute) ?? 0
    }

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

    func shouldSendWindReminder() -> Bool {
        masterEnabled && windReminder
    }

    func shouldSendDailySummary() -> Bool {
        masterEnabled && dailySummary
    }

    func shouldSendEvolutionReady() -> Bool {
        masterEnabled && evolutionReady
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
