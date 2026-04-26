import Foundation

/// Centralized constants for the app
enum AppConstants {
    /// App Group identifier for sharing data between app and extensions
    static let appGroupIdentifier = "group.com.janpodmolik.Uuumi"

    /// Default monitoring limit in minutes (minutes until blow away for debug)
    static let defaultMonitoringLimitMinutes = 25

    /// Minimum threshold in seconds for DeviceActivity events
    static let minimumThresholdSeconds = 6

    /// Logging subsystem identifier
    static let loggingSubsystem = "com.janpodmolik.Uuumi"

    // MARK: - Timing

    /// Cooldown between notification permission re-prompts (7 days)
    static let notificationPromptCooldown: TimeInterval = 7 * 24 * 60 * 60

    /// Debounce delay for selection saves (in nanoseconds) - 300ms
    static let selectionDebounceNanoseconds: UInt64 = 300_000_000

    // MARK: - Monitoring

    /// Maximum thresholds per schedule (DeviceActivity API limit is ~20)
    static let maxThresholds = 20

    /// Thresholds reserved for non-wind events:
    ///   - 1 day-start sentinel (early-day shield activation)
    ///   - 1 over-limit safety net (PHANTOM_BURST_WORKAROUND — see below)
    static let reservedThresholds = 2

    /// Over-limit safety net threshold position, expressed as numerator/denominator of `limitSeconds`.
    /// PHANTOM_BURST_WORKAROUND — sub-limit thresholds end exactly at 100% of the limit. If the
    /// phantom-burst guard drops the 100% event, no further threshold ever fires and the user can
    /// keep using limited apps with wind frozen near 100%. This extra threshold past the limit
    /// guarantees a follow-up event that activates the safety shield. 110% chosen because at the
    /// longest configurable limit (20 min) the gap to 100% is ~2 min — small enough to catch over-use
    /// quickly, large enough that the inter-event delta check still has headroom.
    static let overLimitThresholdNumerator = 11
    static let overLimitThresholdDenominator = 10

    // MARK: - UI

    /// Maximum apps to display initially in activity report
    static let maxDisplayedApps = 8

    // MARK: - Pet Input Limits

    static let maxPetNameLength = 15
    static let maxPetPurposeLength = 30

    // MARK: - iOS 26.2 Phantom Burst Workaround (FB21450954)
    // Grep for PHANTOM_BURST_WORKAROUND to find all call sites that need removal
    // once Apple ships the fix. Bump this version at each app release and run the
    // app once on the latest iOS — if phantomBurstAssumedFixedVersion has been
    // reached and no phantom drops are recorded in normal testing, the workaround
    // (and this constant) can be deleted.
    // Tracking thread: https://developer.apple.com/forums/thread/811305
    /// iOS version where Apple is expected to have fixed the DeviceActivity bug.
    /// Community reports point at 26.5 beta — treat as "revisit this in every release
    /// after user base has moved past this version."
    static let phantomBurstAssumedFixedVersion = OperatingSystemVersion(
        majorVersion: 26, minorVersion: 5, patchVersion: 0
    )
}

/// Logging category identifiers
enum LogCategories {
    static let extensionSubsystem = "com.janpodmolik.Uuumi.DeviceActivityMonitor"
    static let shieldSubsystem = "com.janpodmolik.Uuumi.ShieldConfiguration"
}

/// Deep link URLs for navigation
enum DeepLinks {
    static let shield = "uuumi://shield"
    static let home = "uuumi://home"
    static let dailySummary = "uuumi://dailySummary"
    static let presetPicker = "uuumi://preset-picker"

    /// Creates a pet-specific deep link
    static func pet(_ id: UUID) -> String {
        "uuumi://pet/\(id.uuidString)"
    }
}

/// Event name patterns for DeviceActivity
enum EventNames {
    static let secondPrefix = "second_"
    static let dayStartSentinel = "daystart_sentinel"
    /// PHANTOM_BURST_WORKAROUND — over-limit safety net. Distinct prefix so the
    /// monitor extension can recognize over-limit events and skip the phantom-burst drop.
    static let overLimitPrefix = "overlimit_"
}

/// Darwin notification names for cross-process IPC (extension → main app)
enum DarwinNotifications {
    static let safetyShieldActivated = "com.janpodmolik.Uuumi.SafetyShieldActivated"
}

enum Gender: String, CaseIterable {
    case notSpecified = "not_specified"
    case male = "male"
    case female = "female"
}

/// UserDefaults keys
enum DefaultsKeys {
    static let lastMonitorUpdate = "lastMonitorUpdate"

    // MARK: - Pet Persistence

    static let activePet = "activePet"

    // MARK: - Monitoring Context (lightweight data for extensions)

    static let monitoredPetId = "monitoredPetId"
    static let monitoredPetName = "monitoredPetName"
    static let monitoredWindPoints = "monitoredWindPoints"
    static let monitoringLimitSeconds = "monitoringLimitSeconds"
    static let monitoredLastThresholdSeconds = "monitoredLastThresholdSeconds"
    static let monitoredRiseRate = "monitoredRiseRate"
    static let breakStartedAt = "breakStartedAt"

    // MARK: - Token Storage

    static let applicationTokens = "applicationTokens"
    static let categoryTokens = "categoryTokens"
    static let webDomainTokens = "webDomainTokens"
    static let familyActivitySelection = "familyActivitySelection"
    static let myAppsSelection = "myAppsSelection"

    // MARK: - Limit Settings

    static let limitSettings = "limitSettings"
    static let isDayStartShieldActive = "isDayStartShieldActive"
    static let todaySelectedPreset = "todaySelectedPreset"
    static let lastKnownWindLevel = "lastKnownWindLevel"
    static let isShieldActive = "isShieldActive"

    // MARK: - Shield Wind Decrease

    static let shieldActivatedAt = "shieldActivatedAt"
    static let monitoredFallRate = "monitoredFallRate"
    static let totalBreakReduction = "totalBreakReduction"

    // MARK: - Break Type

    static let currentBreakType = "currentBreakType"
    static let committedBreakMode = "committedBreakMode"
    static let windZeroNotified = "windZeroNotified"
    static let windReminderSent = "windReminderSent"

    // MARK: - Shield Unlock Redirect

    static let pendingShieldUnlock = "pendingShieldUnlock"

    // MARK: - Break Picker Preferences

    static let preferredBreakType = "preferredBreakType"
    static let preferredCommittedMinutes = "preferredCommittedMinutes"

    // MARK: - Pending Coin Rewards

    static let pendingCoinsAwarded = "pendingCoinsAwarded"

    // MARK: - Cumulative Tracking

    static let cumulativeBaseline = "cumulativeBaseline"

    // MARK: - Monitoring Safety

    static let lastThresholdTimestamp = "lastThresholdTimestamp"
    static let lastMonitoringRestart = "lastMonitoringRestart"

    // MARK: - iOS 26.2 Phantom Burst Diagnostics (FB21450954)
    // Tracks events the physical-limit guard dropped. Surfaced in the Troubleshooting
    // screen so users see evidence that the app is actively filtering Apple's bug.
    static let lastBurstDropAt = "lastBurstDropAt"
    static let burstDropCount = "burstDropCount"
    static let burstDropSecondsTotal = "burstDropSecondsTotal"

    /// Wall-clock start of the currently-running DeviceActivity interval (set in intervalDidStart).
    /// Used by the phantom-burst validator to reject events whose `current` seconds exceed
    /// how long the interval has actually been running.
    static let currentIntervalStartedAt = "currentIntervalStartedAt"

    // MARK: - Daily Reset

    static let lastDayResetDate = "lastDayResetDate"

    // MARK: - Hourly Aggregate

    static let hourlyAggregate = "hourlyAggregate"
    static let hourlyHistory = "hourlyHistory"

    // MARK: - Authorization

    static let wasEverAuthorized = "wasEverAuthorized"

    // MARK: - Post-Reinstall Reselection

    static let needsAppReselection = "needsAppReselection"

    // MARK: - User Data Sync

    static let lastUserDataSync = "lastUserDataSync"

    // MARK: - Onboarding

    static let hasCompletedOnboarding = "hasCompletedOnboarding"

    // MARK: - Premium Cache

    static let isPremiumCached = "isPremiumCached"

    // MARK: - Appearance Preferences

    static let appearanceMode = "appearanceMode"
    static let useDynamicSky = "useDynamicSky"
    static let selectedDayTheme = "selectedDayTheme"
    static let selectedNightTheme = "selectedNightTheme"
    static let lockButtonSide = "lockButtonSide"
    static let lockButtonSize = "lockButtonSize"

    // MARK: - Notification Re-prompt

    static let lastNotificationPromptDate = "lastNotificationPromptDate"

    // MARK: - Demographics

    static let gender = "gender"
}
