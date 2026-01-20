import Foundation

/// Centralized constants for the app
enum AppConstants {
    /// App Group identifier for sharing data between app and extensions
    static let appGroupIdentifier = "group.com.janpodmolik.Clif"

    /// Default daily screen time limit in minutes
    static let defaultDailyLimitMinutes = 25

    /// Minimum threshold in seconds for DeviceActivity events
    static let minimumThresholdSeconds = 6

    /// Logging subsystem identifier
    static let loggingSubsystem = "com.janpodmolik.Clif"

    // MARK: - Timing

    /// Debounce delay for selection saves (in nanoseconds) - 300ms
    static let selectionDebounceNanoseconds: UInt64 = 300_000_000

    // MARK: - Monitoring

    /// Daily mode: percentage thresholds for monitoring events (10% intervals)
    static let dailyThresholdPercentages = [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]

    /// Daily mode: percentage at which shield activates
    static let shieldActivationPercentage = 90

    /// Dynamic mode: maximum thresholds per schedule (DeviceActivity API limit is ~20)
    static let maxDynamicThresholds = 20

    // MARK: - UI

    /// Maximum apps to display initially in activity report
    static let maxDisplayedApps = 8
}

/// Logging category identifiers
enum LogCategories {
    static let extensionSubsystem = "com.janpodmolik.Clif.DeviceActivityMonitor"
    static let shieldSubsystem = "com.janpodmolik.Clif.ShieldConfiguration"
}

/// UserDefaults keys
enum DefaultsKeys {
    static let currentProgress = "currentProgress"
    static let dailyLimitMinutes = "dailyLimitMinutes"
    static let selection = "selection"
    static let lastMonitorUpdate = "lastMonitorUpdate"
    static let notification90Sent = "notification90Sent"
    static let notificationLastMinuteSent = "notificationLastMinuteSent"

    // MARK: - Pet Persistence (Active in SharedDefaults for extension access)

    static let activeDailyPets = "activeDailyPets"
    static let activeDynamicPets = "activeDynamicPets"

    // Legacy key - now using separate keys above
    static let archivedPets = "archivedPets"

    // MARK: - Monitoring Context (lightweight data for extensions)

    static let monitoredPetId = "monitoredPetId"
    static let monitoredPetMode = "monitoredPetMode"
    static let monitoredWindPoints = "monitoredWindPoints"
    static let breakStartedAt = "breakStartedAt"
    static let shouldRestartMonitoring = "shouldRestartMonitoring"
}
