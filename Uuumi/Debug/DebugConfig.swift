import Foundation

/// Debug configuration for testing wind mechanics with accelerated timing.
/// Only active in DEBUG builds - production uses WindPreset values directly.
/// Values are persisted to UserDefaults for convenience across app restarts.
enum DebugConfig {
    #if DEBUG
    private static let defaults = UserDefaults.standard
    private static let keyPrefix = "debugConfig_"

    /// Whether to use debug overrides for wind timing.
    /// Set to false to test with production values.
    static var isEnabled: Bool {
        get { defaults.object(forKey: keyPrefix + "isEnabled") as? Bool ?? true }
        set { defaults.set(newValue, forKey: keyPrefix + "isEnabled") }
    }

    // MARK: - Wind Rise (during app usage)

    /// Debug override: minutes of blocked app usage to reach blow away.
    /// Production: 5-15 minutes depending on preset.
    /// Debug: 1 minute for fast testing.
    static var minutesToBlowAway: Double {
        get {
            let value = defaults.double(forKey: keyPrefix + "minutesToBlowAway")
            return value > 0 ? value : 1
        }
        set { defaults.set(newValue, forKey: keyPrefix + "minutesToBlowAway") }
    }

    // MARK: - Wind Fall (during breaks)

    /// Debug override: minutes of break to fully recover.
    /// Production: 15-30 minutes depending on preset.
    /// Debug: 1 minute for fast testing (same as rise for symmetry).
    static var minutesToRecover: Double {
        get {
            let value = defaults.double(forKey: keyPrefix + "minutesToRecover")
            return value > 0 ? value : 1
        }
        set { defaults.set(newValue, forKey: keyPrefix + "minutesToRecover") }
    }

    // MARK: - Computed Rates

    /// Wind points gained per minute of blocked app usage.
    static var riseRate: Double {
        100 / minutesToBlowAway
    }

    /// Wind points decreased per minute during a break.
    static var fallRate: Double {
        100 / minutesToRecover
    }
    #else
    static let isEnabled = false
    #endif
}
