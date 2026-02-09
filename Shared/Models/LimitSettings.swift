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

    /// Default wind preset raw value pre-selected in DailyPresetPicker.
    /// Use `WindPreset(rawValue:)` in the main app to convert.
    var defaultWindPresetRaw: String = "balanced"

    // MARK: - Safety Shield

    /// Wind percentage at which safety shield auto-activates (80 or 100).
    var safetyShieldActivationThreshold: Int = 100

    /// Wind must drop below this percentage for safe unlock (0, 50, or 80).
    var safetyUnlockThreshold: Int = 80

    // MARK: - Post-Break

    /// Automatically activate a free break after committed break completes.
    var autoLockAfterCommittedBreak: Bool = false

    // MARK: - Debug Settings

    /// DEBUG ONLY: Disable the safety shield entirely.
    /// When true, no shield activates at threshold - pet can blow away without warning.
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
        case defaultWindPresetRaw = "defaultWindPreset"
        case safetyShieldActivationThreshold
        case safetyUnlockThreshold
        case autoLockAfterCommittedBreak
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
        self.defaultWindPresetRaw = try container.decodeIfPresent(String.self, forKey: .defaultWindPresetRaw) ?? "balanced"
        self.safetyShieldActivationThreshold = try container.decodeIfPresent(Int.self, forKey: .safetyShieldActivationThreshold) ?? 100
        self.safetyUnlockThreshold = try container.decodeIfPresent(Int.self, forKey: .safetyUnlockThreshold) ?? 80
        self.autoLockAfterCommittedBreak = try container.decodeIfPresent(Bool.self, forKey: .autoLockAfterCommittedBreak) ?? false
        self.disableSafetyShield = try container.decodeIfPresent(Bool.self, forKey: .disableSafetyShield) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(notifications, forKey: .notifications)
        try container.encode(dayStartShieldEnabled, forKey: .dayStartShieldEnabled)
        try container.encode(defaultWindPresetRaw, forKey: .defaultWindPresetRaw)
        try container.encode(safetyShieldActivationThreshold, forKey: .safetyShieldActivationThreshold)
        try container.encode(safetyUnlockThreshold, forKey: .safetyUnlockThreshold)
        try container.encode(autoLockAfterCommittedBreak, forKey: .autoLockAfterCommittedBreak)
        try container.encode(disableSafetyShield, forKey: .disableSafetyShield)
        // notificationMode is intentionally NOT encoded — migration is one-way
    }
}
