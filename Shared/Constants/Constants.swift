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

    /// Debounce delay for selection saves (in nanoseconds) - 300ms
    static let selectionDebounceNanoseconds: UInt64 = 300_000_000

    // MARK: - Monitoring

    /// Maximum thresholds per schedule (DeviceActivity API limit is ~20)
    static let maxThresholds = 20

    // MARK: - UI

    /// Maximum apps to display initially in activity report
    static let maxDisplayedApps = 8
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
}

/// Darwin notification names for cross-process IPC (extension → main app)
enum DarwinNotifications {
    static let safetyShieldActivated = "com.janpodmolik.Uuumi.SafetyShieldActivated"
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
    static let windPresetLockedForToday = "windPresetLockedForToday"
    static let windPresetLockedDate = "windPresetLockedDate"
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

    // MARK: - Daily Reset

    static let lastDayResetDate = "lastDayResetDate"

    // MARK: - Hourly Aggregate

    static let hourlyAggregate = "hourlyAggregate"

    // MARK: - Authorization

    static let wasEverAuthorized = "wasEverAuthorized"

    // MARK: - Post-Reinstall Reselection

    static let needsAppReselection = "needsAppReselection"

    // MARK: - User Data Sync

    static let lastUserDataSync = "lastUserDataSync"

    // MARK: - Appearance Preferences

    static let appearanceMode = "appearanceMode"
    static let selectedDayTheme = "selectedDayTheme"
    static let selectedNightTheme = "selectedNightTheme"
    static let lockButtonSide = "lockButtonSide"
}
