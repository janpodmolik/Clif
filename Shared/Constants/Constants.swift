import Foundation

/// Centralized constants for the app
enum AppConstants {
    /// App Group identifier for sharing data between app and extensions
    static let appGroupIdentifier = "group.com.janpodmolik.Clif"

    /// Default monitoring limit in minutes (minutes until blow away for debug)
    static let defaultMonitoringLimitMinutes = 25

    /// Minimum threshold in seconds for DeviceActivity events
    static let minimumThresholdSeconds = 6

    /// Logging subsystem identifier
    static let loggingSubsystem = "com.janpodmolik.Clif"

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
    static let extensionSubsystem = "com.janpodmolik.Clif.DeviceActivityMonitor"
    static let shieldSubsystem = "com.janpodmolik.Clif.ShieldConfiguration"
}

/// Deep link URLs for navigation
enum DeepLinks {
    static let shield = "clif://shield"
    static let home = "clif://home"
    static let presetPicker = "clif://preset-picker"

    /// Creates a pet-specific deep link
    static func pet(_ id: UUID) -> String {
        "clif://pet/\(id.uuidString)"
    }
}

/// Event name patterns for DeviceActivity
enum EventNames {
    static let secondPrefix = "second_"
}

/// UserDefaults keys
enum DefaultsKeys {
    static let lastMonitorUpdate = "lastMonitorUpdate"

    // MARK: - Pet Persistence

    static let activePet = "activePet"

    // MARK: - Monitoring Context (lightweight data for extensions)

    static let monitoredPetId = "monitoredPetId"
    static let monitoredWindPoints = "monitoredWindPoints"
    static let monitoringLimitSeconds = "monitoringLimitSeconds"
    static let monitoredLastThresholdSeconds = "monitoredLastThresholdSeconds"
    static let monitoredRiseRate = "monitoredRiseRate"
    static let breakStartedAt = "breakStartedAt"

    // MARK: - Token Storage

    static let applicationTokens = "applicationTokens"
    static let categoryTokens = "categoryTokens"
    static let webDomainTokens = "webDomainTokens"

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
    static let committedBreakDuration = "committedBreakDuration"
    static let windZeroNotified = "windZeroNotified"

    // MARK: - Cumulative Tracking

    static let cumulativeBaseline = "cumulativeBaseline"

    // MARK: - Daily Reset

    static let lastDayResetDate = "lastDayResetDate"
}
