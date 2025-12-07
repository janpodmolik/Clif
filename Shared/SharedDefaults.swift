import Foundation
import FamilyControls

/// Shared UserDefaults wrapper for communication between main app and extensions.
/// Uses App Group container for cross-process data sharing.
struct SharedDefaults {
    
    // MARK: - Private
    
    private static let defaults: UserDefaults? = {
        // Try to get App Group container
        guard let ud = UserDefaults(suiteName: AppConstants.appGroupIdentifier) else {
            #if DEBUG
            print("SharedDefaults: Failed to create UserDefaults for App Group")
            #endif
            return nil
        }
        
        // Force a read to initialize the container and suppress the CFPrefs warning
        _ = ud.object(forKey: "init")
        
        return ud
    }()
    
    // MARK: - Progress
    
    static var currentProgress: Int {
        get { defaults?.integer(forKey: DefaultsKeys.currentProgress) ?? 0 }
        set { defaults?.set(newValue, forKey: DefaultsKeys.currentProgress) }
    }
    
    static var lastMonitorUpdate: Date? {
        get { defaults?.object(forKey: DefaultsKeys.lastMonitorUpdate) as? Date }
        set { defaults?.set(newValue, forKey: DefaultsKeys.lastMonitorUpdate) }
    }
    
    // MARK: - Settings
    
    static var dailyLimitMinutes: Int {
        get { 
            let value = defaults?.integer(forKey: DefaultsKeys.dailyLimitMinutes) ?? 0
            return value > 0 ? value : AppConstants.defaultDailyLimitMinutes
        }
        set { defaults?.set(newValue, forKey: DefaultsKeys.dailyLimitMinutes) }
    }
    
    // MARK: - Selection
    
    static var selection: FamilyActivitySelection? {
        get {
            guard let data = defaults?.data(forKey: DefaultsKeys.selection) else { return nil }
            return try? PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        }
        set {
            if let newValue, let data = try? PropertyListEncoder().encode(newValue) {
                defaults?.set(data, forKey: DefaultsKeys.selection)
            } else {
                defaults?.removeObject(forKey: DefaultsKeys.selection)
            }
        }
    }
}
