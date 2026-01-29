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

    /// Timestamp when current break started (for calculating actualMinutes on break end).
    static var breakStartedAt: Date? {
        get { defaults?.object(forKey: DefaultsKeys.breakStartedAt) as? Date }
        set { defaults?.set(newValue, forKey: DefaultsKeys.breakStartedAt) }
    }

    /// Current break type as raw string. Nil when no break is active.
    /// Prefer `activeBreakType` for typed access.
    static var currentBreakType: String? {
        get { defaults?.string(forKey: DefaultsKeys.currentBreakType) }
        set { defaults?.set(newValue, forKey: DefaultsKeys.currentBreakType) }
    }

    /// Typed accessor for current break type.
    /// Setting this automatically syncs `isShieldActive` (non-nil = active).
    static var activeBreakType: BreakType? {
        get {
            guard let raw = currentBreakType else { return nil }
            return BreakType(rawValue: raw)
        }
        set {
            currentBreakType = newValue?.rawValue
            isShieldActive = newValue != nil
        }
    }

    /// Duration for committed break in minutes.
    /// Positive values = minutes (5-120)
    /// -1 = until wind reaches 0%
    /// -2 = until end of day
    /// nil = not set (free break or no break)
    static var committedBreakDuration: Int? {
        get { defaults?.object(forKey: DefaultsKeys.committedBreakDuration) as? Int }
        set {
            if let value = newValue {
                defaults?.set(value, forKey: DefaultsKeys.committedBreakDuration)
            } else {
                defaults?.removeObject(forKey: DefaultsKeys.committedBreakDuration)
            }
        }
    }

    // MARK: - Shield Helpers

    /// Resets usage shield flags to allow wind tracking.
    /// Does NOT reset isDayStartShieldActive - that's only cleared when user selects a preset.
    static func resetShieldFlags() {
        activeBreakType = nil  // also sets isShieldActive = false
        shieldActivatedAt = nil
        breakStartedAt = nil
        committedBreakDuration = nil
    }
}
