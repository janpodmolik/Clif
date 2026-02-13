import Foundation

extension SharedDefaults {

    // MARK: - Day State & Presets

    /// Whether day start shield is currently active (set at day reset, cleared on preset selection).
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

    /// Date of last daily reset (start of day). Used to detect new day in extension.
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
    /// Called automatically by extension at intervalDidStart or manually from app.
    static func resetForNewDay(dayStartShieldEnabled: Bool) {
        // Reset wind (includes preset lock)
        resetWindState()
        todaySelectedPreset = nil

        // Set day start shield based on user preference
        isDayStartShieldActive = dayStartShieldEnabled

        // Record reset date
        lastDayResetDate = Calendar.current.startOfDay(for: Date())

        synchronize()
    }

    /// Performs daily reset if it's a new day. Returns true if reset was performed.
    @discardableResult
    static func performDailyResetIfNeeded() -> Bool {
        guard isNewDay else { return false }

        let settings = limitSettings
        resetForNewDay(dayStartShieldEnabled: settings.dayStartShieldEnabled)
        return true
    }
}
