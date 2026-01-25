import Foundation

extension SharedDefaults {

    // MARK: - Day State & Presets

    /// Whether morning shield is currently active (set at day reset, cleared on preset selection).
    /// Note: Uses fresh UserDefaults instance for reads to ensure cross-process sync.
    static var isMorningShieldActive: Bool {
        get {
            let fresh = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
            fresh?.synchronize()
            return fresh?.bool(forKey: DefaultsKeys.isMorningShieldActive) ?? false
        }
        set {
            defaults?.set(newValue, forKey: DefaultsKeys.isMorningShieldActive)
            defaults?.synchronize()
        }
    }

    /// Whether wind preset is locked for today (after first unlock or selection).
    static var windPresetLockedForToday: Bool {
        get { defaults?.bool(forKey: DefaultsKeys.windPresetLockedForToday) ?? false }
        set { defaults?.set(newValue, forKey: DefaultsKeys.windPresetLockedForToday) }
    }

    /// Date when preset was locked (for day boundary checking).
    static var windPresetLockedDate: Date? {
        get { defaults?.object(forKey: DefaultsKeys.windPresetLockedDate) as? Date }
        set { defaults?.set(newValue, forKey: DefaultsKeys.windPresetLockedDate) }
    }

    /// Today's selected preset (nil if not yet selected).
    static var todaySelectedPreset: String? {
        get { defaults?.string(forKey: DefaultsKeys.todaySelectedPreset) }
        set { defaults?.set(newValue, forKey: DefaultsKeys.todaySelectedPreset) }
    }

    /// User-configurable shield and notification settings.
    static var limitSettings: LimitSettings {
        get {
            guard let data = defaults?.data(forKey: DefaultsKeys.limitSettings),
                  let settings = try? JSONDecoder().decode(LimitSettings.self, from: data) else {
                return .default
            }
            return settings
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults?.set(data, forKey: DefaultsKeys.limitSettings)
            }
        }
    }

    // MARK: - Day Reset Helper

    /// Resets all day-specific state for a new day.
    /// Call this at midnight or when user manually resets.
    static func resetForNewDay(morningShieldEnabled: Bool) {
        // Reset wind
        resetWindState()

        // Reset preset lock
        windPresetLockedForToday = false
        todaySelectedPreset = nil

        // Set morning shield based on user preference
        isMorningShieldActive = morningShieldEnabled

        synchronize()
    }
}
