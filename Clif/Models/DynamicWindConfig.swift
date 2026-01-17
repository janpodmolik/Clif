import Foundation

/// Configuration for Dynamic Wind mode behavior.
struct DynamicWindConfig: Codable, Equatable {
    /// Wind points gained per minute of blocked app usage.
    /// Default: 10 (reaches 100 in 10 minutes)
    var riseRate: Double

    /// Whether wind resets to 0 at midnight.
    /// Default: false (wind persists across days)
    var dailyReset: Bool

    init(
        riseRate: Double = 10.0,
        dailyReset: Bool = false
    ) {
        self.riseRate = riseRate
        self.dailyReset = dailyReset
    }

    /// Minutes of blocked app usage to reach blow away (wind = 100).
    var minutesToBlowAway: Double {
        guard riseRate > 0 else { return .infinity }
        return 100 / riseRate
    }
}

// MARK: - Presets

extension DynamicWindConfig {
    /// Default configuration: 10 wind/min, no daily reset.
    static let `default` = DynamicWindConfig()

    /// Relaxed configuration: 5 wind/min (20 min to blow away).
    static let relaxed = DynamicWindConfig(riseRate: 5.0)

    /// Strict configuration: 20 wind/min (5 min to blow away).
    static let strict = DynamicWindConfig(riseRate: 20.0)
}
