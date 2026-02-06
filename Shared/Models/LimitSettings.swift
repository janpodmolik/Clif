import Foundation

/// Notification verbosity level for wind warnings.
enum NotificationMode: String, Codable, CaseIterable {
    /// No notifications
    case off
    /// Only critical (85%) notification
    case important
    /// All notifications (25%, 60%, 85%)
    case all

    var label: String {
        switch self {
        case .off: return "Vypnuto"
        case .important: return "Jen důležité"
        case .all: return "Všechny"
        }
    }

    var description: String {
        switch self {
        case .off: return "Žádné notifikace o větru"
        case .important: return "Upozorní jen při kritickém větru (85%)"
        case .all: return "Upozorní při 25%, 60% a 85%"
        }
    }

    func shouldSend(_ notification: WindNotification) -> Bool {
        switch self {
        case .off: return false
        case .important: return notification == .critical
        case .all: return true
        }
    }
}

/// User-configurable settings for notifications and safety shield.
/// Stored in SharedDefaults for access from both app and extensions.
/// Note: Shields are activated manually (break button) or at 100% (safety shield).
struct LimitSettings: Codable, Equatable {

    // MARK: - Notification Settings

    /// Notification verbosity level.
    var notificationMode: NotificationMode = .all

    /// Legacy: migrated to notificationMode. Kept for backwards compatibility decoding.
    private var enabledNotifications: Set<WindNotification>?

    // MARK: - Day Start Shield

    /// Enable Day Start Shield (shield active after day reset until preset selected).
    var dayStartShieldEnabled: Bool = true

    // MARK: - Debug Settings

    /// DEBUG ONLY: Disable the 100% safety shield.
    /// When true, no shield activates at 100% - pet can blow away without warning.
    /// Default: false (safety shield always active)
    var disableSafetyShield: Bool = false

    // MARK: - Defaults

    static let `default` = LimitSettings()
}
