import Foundation

extension SharedDefaults {

    // MARK: - Day State & Presets

    /// Whether day start shield is currently active.
    /// Set reactively by extension on first threshold of a new day, cleared when preset is applied.
    /// Note: Uses fresh UserDefaults instance for reads to ensure cross-process sync.
    static var isDayStartShieldActive: Bool {
        get {
            let fresh = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
            fresh?.synchronize()
            return fresh?.bool(forKey: DefaultsKeys.isDayStartShieldActive) ?? false
        }
        set {
            defaults?.set(newValue, forKey: DefaultsKeys.isDayStartShieldActive)
            defaults?.synchronize()
        }
    }

    /// Today's selected preset (nil if not yet selected).
    static var todaySelectedPreset: String? {
        get { defaults?.string(forKey: DefaultsKeys.todaySelectedPreset) }
        set { defaults?.set(newValue, forKey: DefaultsKeys.todaySelectedPreset) }
    }

    /// Date of last daily reset (start of day). Used to detect new day in extension and app.
    static var lastDayResetDate: Date? {
        get { defaults?.object(forKey: DefaultsKeys.lastDayResetDate) as? Date }
        set { defaults?.set(newValue, forKey: DefaultsKeys.lastDayResetDate) }
    }

    /// Checks if today is a new day compared to last reset.
    static var isNewDay: Bool {
        guard let lastReset = lastDayResetDate else { return true }
        let today = Calendar.current.startOfDay(for: Date())
        return lastReset < today
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
    /// Called from applyPreset when the user selects a daily preset.
    static func resetForNewDay() {
        resetWindState()
        todaySelectedPreset = nil
        isDayStartShieldActive = false
        lastDayResetDate = Calendar.current.startOfDay(for: Date())
        synchronize()
    }
}
