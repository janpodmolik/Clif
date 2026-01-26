import Foundation

extension SharedDefaults {

    // MARK: - Shield State

    /// Whether shield is currently active (wind should not increase while true).
    /// Note: Uses fresh UserDefaults instance for reads to ensure cross-process sync.
    static var isShieldActive: Bool {
        get {
            let fresh = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
            fresh?.synchronize()
            return fresh?.bool(forKey: DefaultsKeys.isShieldActive) ?? false
        }
        set {
            defaults?.set(newValue, forKey: DefaultsKeys.isShieldActive)
            defaults?.synchronize()
        }
    }

    /// Timestamp when shield was activated (for calculating wind decrease during shield time).
    static var shieldActivatedAt: Date? {
        get { defaults?.object(forKey: DefaultsKeys.shieldActivatedAt) as? Date }
        set { defaults?.set(newValue, forKey: DefaultsKeys.shieldActivatedAt) }
    }

    /// Timestamp until which shield cooldown is active.
    /// During cooldown, safety shield will NOT auto-activate at 100%.
    /// Note: Uses fresh UserDefaults instance for reads to ensure cross-process sync.
    static var shieldCooldownUntil: Date? {
        get {
            let fresh = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
            fresh?.synchronize()
            return fresh?.object(forKey: DefaultsKeys.shieldCooldownUntil) as? Date
        }
        set {
            defaults?.set(newValue, forKey: DefaultsKeys.shieldCooldownUntil)
            defaults?.synchronize()
        }
    }

    /// Timestamp when current break started (for calculating actualMinutes on break end).
    static var breakStartedAt: Date? {
        get { defaults?.object(forKey: DefaultsKeys.breakStartedAt) as? Date }
        set { defaults?.set(newValue, forKey: DefaultsKeys.breakStartedAt) }
    }

    // MARK: - Shield Helpers

    /// Resets usage shield flags to allow wind tracking.
    /// Does NOT reset isDayStartShieldActive - that's only cleared when user selects a preset.
    static func resetShieldFlags() {
        isShieldActive = false
        shieldActivatedAt = nil
        synchronize()
    }
}
