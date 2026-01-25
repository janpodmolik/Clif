import Foundation

/// Single source of truth for wind calculation.
/// Consolidates wind logic that was previously scattered across:
/// - DeviceActivityMonitorExtension (threshold events)
/// - ScreenTimeManager (break reduction)
/// - Pet (effectiveWindPoints during shield)
enum WindCalculator {

    // MARK: - Core Calculation

    /// Calculates wind from raw values using the absolute formula:
    /// `wind = (cumulativeSeconds - breakReduction) / limitSeconds * 100`
    ///
    /// - Parameters:
    ///   - cumulativeSeconds: Total usage seconds from DeviceActivity threshold
    ///   - breakReduction: Total seconds "forgiven" by breaks today
    ///   - limitSeconds: Daily limit in seconds (from preset)
    /// - Returns: Wind points (0+, can exceed 100 for blow-away detection)
    static func calculate(
        cumulativeSeconds: Int,
        breakReduction: Int,
        limitSeconds: Int
    ) -> Double {
        guard limitSeconds > 0 else { return 0 }
        let effectiveSeconds = max(0, cumulativeSeconds - breakReduction)
        // Note: Wind can exceed 100% to allow blow-away detection at 105%
        return Double(effectiveSeconds) / Double(limitSeconds) * 100
    }

    // MARK: - Convenience Methods

    /// Current wind calculated from SharedDefaults values.
    /// Use this when you need the wind value but shield is not active.
    static func currentWind() -> Double {
        calculate(
            cumulativeSeconds: SharedDefaults.monitoredLastThresholdSeconds,
            breakReduction: SharedDefaults.totalBreakReduction,
            limitSeconds: SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
        )
    }

    /// Real-time wind during active shield.
    /// Wind decreases over time based on fallRate while shield is active.
    ///
    /// - Parameters:
    ///   - shieldActivatedAt: When the shield was activated (nil if not active)
    ///   - fallRate: Wind decrease rate in points per second
    /// - Returns: Effective wind points accounting for shield recovery
    static func effectiveWind(shieldActivatedAt: Date?, fallRate: Double) -> Double {
        let baseWind = currentWind()
        guard let activatedAt = shieldActivatedAt else { return baseWind }
        let elapsed = Date().timeIntervalSince(activatedAt)
        return max(0, baseWind - elapsed * fallRate)
    }

    /// Real-time wind using SharedDefaults for shield state.
    /// Convenience method that reads shieldActivatedAt and fallRate from SharedDefaults.
    static func effectiveWind() -> Double {
        effectiveWind(
            shieldActivatedAt: SharedDefaults.shieldActivatedAt,
            fallRate: SharedDefaults.monitoredFallRate
        )
    }
}
