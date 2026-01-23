import Foundation

/// Debug configuration for testing wind mechanics with accelerated timing.
/// Only active in DEBUG builds - production uses WindPreset values directly.
enum DebugConfig {
    #if DEBUG
    /// Whether to use debug overrides for wind timing.
    /// Set to false to test with production values.
    static var isEnabled = true

    // MARK: - Wind Rise (during app usage)

    /// Debug override: minutes of blocked app usage to reach blow away.
    /// Production: 5-15 minutes depending on preset.
    /// Debug: 1 minute for fast testing.
    static var minutesToBlowAway: Double = 1

    // MARK: - Wind Fall (during breaks)

    /// Debug override: minutes of break to fully recover.
    /// Production: 15-30 minutes depending on preset.
    /// Debug: 2 minutes for fast testing.
    static var minutesToRecover: Double = 2

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
