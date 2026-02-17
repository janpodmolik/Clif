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

    /// Mode for committed break. Nil when no committed break is active.
    static var committedBreakMode: CommittedBreakMode? {
        get {
            guard let data = defaults?.data(forKey: DefaultsKeys.committedBreakMode) else { return nil }
            return try? JSONDecoder().decode(CommittedBreakMode.self, from: data)
        }
        set {
            if let value = newValue, let data = try? JSONEncoder().encode(value) {
                defaults?.set(data, forKey: DefaultsKeys.committedBreakMode)
            } else {
                defaults?.removeObject(forKey: DefaultsKeys.committedBreakMode)
            }
        }
    }

    /// Whether the "wind reached 0%" notification was already sent during this break.
    /// Used for both free and safety breaks. Reset when shield flags are cleared.
    static var windZeroNotified: Bool {
        get { defaults?.bool(forKey: DefaultsKeys.windZeroNotified) ?? false }
        set { defaults?.set(newValue, forKey: DefaultsKeys.windZeroNotified) }
    }

    // MARK: - Shield Helpers

    /// Resets usage shield flags to allow wind tracking.
    /// Does NOT reset isDayStartShieldActive - that's only cleared when user selects a preset.
    static func resetShieldFlags() {
        activeBreakType = nil  // also sets isShieldActive = false
        shieldActivatedAt = nil
        breakStartedAt = nil
        committedBreakMode = nil
        windZeroNotified = false
    }

    // MARK: - Pending Coin Rewards

    /// Coins awarded while the app was not visible (background break end, midnight reset, etc.).
    /// Main app reads this on foreground to show reward animation, then clears it.
    static var pendingCoinsAwarded: Int {
        get { defaults?.integer(forKey: DefaultsKeys.pendingCoinsAwarded) ?? 0 }
        set { defaults?.set(newValue, forKey: DefaultsKeys.pendingCoinsAwarded) }
    }

    /// Result of ending a break at midnight (or simulated midnight in debug).
    struct MidnightBreakResult {
        let breakType: BreakType
        let actualMinutes: Int
        let windPoints: Double
        let petId: UUID?
        let cutoff: Date
    }

    /// Ends any active break at a given cutoff time and resets shield flags.
    /// Returns computed result if a break was active, nil otherwise.
    ///
    /// Callers are responsible for:
    /// - Logging `breakEnded` snapshot event
    /// - Awarding coins for committed breaks
    /// - Deactivating ManagedSettingsStore
    ///
    /// - Parameter cutoff: The logical end time. For real midnight, use `Calendar.current.startOfDay(for: Date())`.
    ///   For debug simulation, use `Date()`.
    static func endBreakAtMidnight(cutoff: Date) -> MidnightBreakResult? {
        guard let breakType = activeBreakType,
              let breakStartedAt = breakStartedAt else {
            return nil
        }

        let elapsed = cutoff.timeIntervalSince(breakStartedAt)
        let actualMinutes = Int(round(max(0, elapsed) / 60))
        let windPoints = monitoredWindPoints
        let petId = monitoredPetId

        resetShieldFlags()
        synchronize()

        return MidnightBreakResult(
            breakType: breakType,
            actualMinutes: actualMinutes,
            windPoints: windPoints,
            petId: petId,
            cutoff: cutoff
        )
    }

    // MARK: - Break Picker Preferences

    /// User's preferred break type for picker (persisted across sessions).
    static var preferredBreakType: BreakType {
        get {
            guard let raw = defaults?.string(forKey: DefaultsKeys.preferredBreakType),
                  let type = BreakType(rawValue: raw),
                  BreakType.selectableCases.contains(type) else {
                return .free
            }
            return type
        }
        set {
            defaults?.set(newValue.rawValue, forKey: DefaultsKeys.preferredBreakType)
        }
    }

    /// User's preferred committed break duration in minutes (persisted across sessions).
    /// Returns 30 as default if not set or zero.
    static var preferredCommittedMinutes: Int {
        get {
            let value = defaults?.integer(forKey: DefaultsKeys.preferredCommittedMinutes) ?? 0
            return value > 0 ? value : 30
        }
        set { defaults?.set(newValue, forKey: DefaultsKeys.preferredCommittedMinutes) }
    }
}
