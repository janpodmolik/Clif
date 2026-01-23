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

/// UserDefaults keys
enum DefaultsKeys {
    static let currentProgress = "currentProgress"
    static let selection = "selection"
    static let lastMonitorUpdate = "lastMonitorUpdate"

    // MARK: - Pet Persistence (Active in SharedDefaults for extension access)

    static let activePets = "activePets"

    // Legacy key - now using separate keys above
    static let archivedPets = "archivedPets"

    // MARK: - Monitoring Context (lightweight data for extensions)

    static let monitoredPetId = "monitoredPetId"
    static let monitoredWindPoints = "monitoredWindPoints"
    static let monitoringLimitSeconds = "monitoringLimitSeconds"
    static let monitoredLastThresholdSeconds = "monitoredLastThresholdSeconds"
    static let monitoredRiseRate = "monitoredRiseRate"
    static let breakStartedAt = "breakStartedAt"
    static let shouldRestartMonitoring = "shouldRestartMonitoring"
}
