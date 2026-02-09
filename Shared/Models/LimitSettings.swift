import Foundation

/// Legacy notification mode. Kept only for backward-compatible decoding.
/// New code should use `NotificationSettings` instead.
enum NotificationMode: String, Codable, CaseIterable {
    case off
    case important
    case all

    var label: String {
        switch self {
        case .off: return "Vypnuto"
        case .important: return "Jen důležité"
        case .all: return "Všechny"
        }
    }
}

/// User-configurable settings for notifications and safety shield.
/// Stored in SharedDefaults for access from both app and extensions.
/// Note: Shields are activated manually (break button) or at 100% (safety shield).
struct LimitSettings: Equatable {

    // MARK: - Notification Settings

    /// Granular notification preferences (replaces legacy notificationMode).
    var notifications: NotificationSettings = .default

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

// MARK: - Codable (with migration from legacy NotificationMode)

extension LimitSettings: Codable {

    private enum CodingKeys: String, CodingKey {
        case notifications
        case notificationMode       // legacy — read-only for migration
        case dayStartShieldEnabled
        case disableSafetyShield
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode new notifications if present, otherwise migrate from legacy mode
        if let notifications = try container.decodeIfPresent(NotificationSettings.self, forKey: .notifications) {
            self.notifications = notifications
        } else if let mode = try container.decodeIfPresent(NotificationMode.self, forKey: .notificationMode) {
            self.notifications = .migrated(from: mode)
        } else {
            self.notifications = .default
        }

        self.dayStartShieldEnabled = try container.decodeIfPresent(Bool.self, forKey: .dayStartShieldEnabled) ?? true
        self.disableSafetyShield = try container.decodeIfPresent(Bool.self, forKey: .disableSafetyShield) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(notifications, forKey: .notifications)
        try container.encode(dayStartShieldEnabled, forKey: .dayStartShieldEnabled)
        try container.encode(disableSafetyShield, forKey: .disableSafetyShield)
        // notificationMode is intentionally NOT encoded — migration is one-way
    }
}
