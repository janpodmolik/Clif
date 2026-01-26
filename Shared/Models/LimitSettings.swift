import Foundation

/// User-configurable settings for notifications and safety shield.
/// Stored in SharedDefaults for access from both app and extensions.
/// Note: Shields are activated manually (break button) or at 100% (safety shield).
struct LimitSettings: Codable, Equatable {

    // MARK: - Notification Settings

    /// Wind notification thresholds that are enabled.
    /// Default: all configurable thresholds (25%, 60%, 85%) - blowAway is always enabled
    var enabledNotifications: Set<WindNotification> = Set(WindNotification.configurableNotifications)

    // MARK: - Morning Shield

    /// Enable Morning Shield (shield active after day reset until preset selected).
    var morningShieldEnabled: Bool = true

    // MARK: - Debug Settings

    /// DEBUG ONLY: Disable the 100% safety shield.
    /// When true, no shield activates at 100% - pet can blow away without warning.
    /// Default: false (safety shield always active)
    var disableSafetyShield: Bool = false

    // MARK: - Defaults

    static let `default` = LimitSettings()
}
