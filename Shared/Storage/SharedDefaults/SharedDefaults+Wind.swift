import Foundation

extension SharedDefaults {

    // MARK: - Wind & Monitoring Context

    /// Pet ID currently being monitored (set by main app when starting monitoring).
    static var monitoredPetId: UUID? {
        get {
            guard let string = defaults?.string(forKey: DefaultsKeys.monitoredPetId) else { return nil }
            return UUID(uuidString: string)
        }
        set {
            defaults?.set(newValue?.uuidString, forKey: DefaultsKeys.monitoredPetId)
        }
    }

    /// Current wind points for the monitored pet (updated by extension on each threshold).
    /// Note: Uses fresh UserDefaults instance for reads to ensure cross-process sync.
    static var monitoredWindPoints: Double {
        get {
            let fresh = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
            fresh?.synchronize()
            return fresh?.double(forKey: DefaultsKeys.monitoredWindPoints) ?? 0
        }
        set {
            defaults?.set(newValue, forKey: DefaultsKeys.monitoredWindPoints)
            defaults?.synchronize()
        }
    }

    /// Last threshold seconds recorded (for calculating wind delta in extension).
    /// Note: Uses fresh UserDefaults instance for reads to ensure cross-process sync.
    static var monitoredLastThresholdSeconds: Int {
        get {
            let fresh = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
            fresh?.synchronize()
            return fresh?.integer(forKey: DefaultsKeys.monitoredLastThresholdSeconds) ?? 0
        }
        set {
            defaults?.set(newValue, forKey: DefaultsKeys.monitoredLastThresholdSeconds)
            defaults?.synchronize()
        }
    }

    /// Rise rate in points per second (set by main app from preset).
    static var monitoredRiseRate: Double {
        get { defaults?.double(forKey: DefaultsKeys.monitoredRiseRate) ?? 12.5 }
        set { defaults?.set(newValue, forKey: DefaultsKeys.monitoredRiseRate) }
    }

    /// Fall rate in points per second (set by main app from preset).
    /// Used to calculate wind decrease while shield is active.
    static var monitoredFallRate: Double {
        get { defaults?.double(forKey: DefaultsKeys.monitoredFallRate) ?? 0 }
        set { defaults?.set(newValue, forKey: DefaultsKeys.monitoredFallRate) }
    }

    /// Daily screen time limit in seconds (set by main app from preset).
    static var monitoringLimitSeconds: Int {
        get { defaults?.integer(forKey: DefaultsKeys.monitoringLimitSeconds) ?? 0 }
        set { defaults?.set(newValue, forKey: DefaultsKeys.monitoringLimitSeconds) }
    }

    /// Baseline cumulative seconds from before monitoring restart.
    /// When iOS restarts monitoring (intervalDidStart), it resets its internal counter to 0.
    /// We save the previous cumulative value here so we can add it to new threshold values.
    /// Note: Uses fresh UserDefaults instance for reads to ensure cross-process sync.
    static var cumulativeBaseline: Int {
        get {
            let fresh = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
            fresh?.synchronize()
            return fresh?.integer(forKey: DefaultsKeys.cumulativeBaseline) ?? 0
        }
        set {
            defaults?.set(newValue, forKey: DefaultsKeys.cumulativeBaseline)
            defaults?.synchronize()
        }
    }

    /// Total seconds "forgiven" by breaks today. Reset at day start.
    /// Used for absolute wind calculation: wind = (cumulative - breakReduction) / limit * 100
    /// Note: Uses fresh UserDefaults instance for reads to ensure cross-process sync.
    static var totalBreakReduction: Int {
        get {
            let fresh = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
            fresh?.synchronize()
            return fresh?.integer(forKey: DefaultsKeys.totalBreakReduction) ?? 0
        }
        set {
            defaults?.set(newValue, forKey: DefaultsKeys.totalBreakReduction)
            defaults?.synchronize()
        }
    }

    /// Last known WindLevel (for detecting level changes in extension).
    static var lastKnownWindLevel: Int {
        get { defaults?.integer(forKey: DefaultsKeys.lastKnownWindLevel) ?? 0 }
        set { defaults?.set(newValue, forKey: DefaultsKeys.lastKnownWindLevel) }
    }

    // MARK: - Wind Helpers

    /// Resets all wind-related values for a new monitoring session.
    static func resetWindState() {
        monitoredWindPoints = 0
        monitoredLastThresholdSeconds = 0
        totalBreakReduction = 0
        cumulativeBaseline = 0
        lastKnownWindLevel = 0
        synchronize()
    }

    // MARK: - Wind Calculation

    /// Total cumulative seconds = baseline (from before restart) + current threshold.
    /// This is the true total usage time for today.
    static var totalCumulativeSeconds: Int {
        cumulativeBaseline + monitoredLastThresholdSeconds
    }

    /// Calculates wind from explicit values.
    /// Formula: wind = (cumulativeSeconds - breakReduction) / limitSeconds * 100
    ///
    /// - Parameters:
    ///   - cumulativeSeconds: Total usage seconds (baseline + current threshold)
    ///   - breakReduction: Total seconds "forgiven" by breaks today
    ///   - limitSeconds: Daily limit in seconds
    /// - Returns: Wind points (0+, can exceed 100 for blow-away detection)
    static func calculateWind(
        cumulativeSeconds: Int,
        breakReduction: Int,
        limitSeconds: Int
    ) -> Double {
        guard limitSeconds > 0 else { return 0 }
        let effectiveSeconds = max(0, cumulativeSeconds - breakReduction)
        return Double(effectiveSeconds) / Double(limitSeconds) * 100
    }

    /// Current wind calculated from stored values.
    /// Uses totalCumulativeSeconds (baseline + lastThreshold) for correct calculation after monitoring restart.
    static var calculatedWind: Double {
        calculateWind(
            cumulativeSeconds: totalCumulativeSeconds,
            breakReduction: totalBreakReduction,
            limitSeconds: integer(forKey: DefaultsKeys.monitoringLimitSeconds)
        )
    }

    /// Effective wind during active shield - decreases over time based on fallRate.
    /// When shield is not active, returns calculatedWind.
    static var effectiveWind: Double {
        guard let activatedAt = shieldActivatedAt else {
            return calculatedWind
        }
        let elapsed = Date().timeIntervalSince(activatedAt)
        return max(0, calculatedWind - elapsed * monitoredFallRate)
    }

    /// Buffer time in seconds (5% of limit).
    /// Used for cooldown calculation after shield unlock.
    static var bufferSeconds: Int {
        let limitSeconds = integer(forKey: DefaultsKeys.monitoringLimitSeconds)
        return limitSeconds / 20 // 5%
    }
}
