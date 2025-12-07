import Foundation

/// Centralized constants for the Clif app
enum AppConstants {
    /// App Group identifier for sharing data between app and extensions
    static let appGroupIdentifier = "group.com.janpodmolik.Clif"
    
    /// Default daily screen time limit in minutes
    static let defaultDailyLimitMinutes = 25
    
    /// Minimum threshold in seconds for DeviceActivity events
    static let minimumThresholdSeconds = 6
    
    /// Logging subsystem identifier
    static let loggingSubsystem = "com.janpodmolik.Clif"
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
}
