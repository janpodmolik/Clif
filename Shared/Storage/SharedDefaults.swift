import Foundation
import FamilyControls
import ManagedSettings

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
    
    // MARK: - Lightweight token access for extensions (avoids full FamilyActivitySelection decode)
    
    static var applicationTokensData: Data? {
        get { defaults?.data(forKey: "applicationTokens") }
        set { defaults?.set(newValue, forKey: "applicationTokens") }
    }
    
    static var categoryTokensData: Data? {
        get { defaults?.data(forKey: "categoryTokens") }
        set { defaults?.set(newValue, forKey: "categoryTokens") }
    }
    
    static var webDomainTokensData: Data? {
        get { defaults?.data(forKey: "webDomainTokens") }
        set { defaults?.set(newValue, forKey: "webDomainTokens") }
    }
    
    static func saveTokens(from selection: FamilyActivitySelection) {
        applicationTokensData = try? PropertyListEncoder().encode(selection.applicationTokens)
        categoryTokensData = try? PropertyListEncoder().encode(selection.categoryTokens)
        webDomainTokensData = try? PropertyListEncoder().encode(selection.webDomainTokens)
    }
    
    static func loadApplicationTokens() -> Set<ApplicationToken>? {
        guard let data = applicationTokensData else { return nil }
        return try? PropertyListDecoder().decode(Set<ApplicationToken>.self, from: data)
    }
    
    static func loadCategoryTokens() -> Set<ActivityCategoryToken>? {
        guard let data = categoryTokensData else { return nil }
        return try? PropertyListDecoder().decode(Set<ActivityCategoryToken>.self, from: data)
    }
    
    static func loadWebDomainTokens() -> Set<WebDomainToken>? {
        guard let data = webDomainTokensData else { return nil }
        return try? PropertyListDecoder().decode(Set<WebDomainToken>.self, from: data)
    }
    
    // MARK: - Notifications
    
    static var notification90Sent: Bool {
        get { defaults?.bool(forKey: DefaultsKeys.notification90Sent) ?? false }
        set { defaults?.set(newValue, forKey: DefaultsKeys.notification90Sent) }
    }
    
    static var notificationLastMinuteSent: Bool {
        get { defaults?.bool(forKey: DefaultsKeys.notificationLastMinuteSent) ?? false }
        set { defaults?.set(newValue, forKey: DefaultsKeys.notificationLastMinuteSent) }
    }

    // MARK: - Raw Data Access (for types not available in extensions)

    static func data(forKey key: String) -> Data? {
        defaults?.data(forKey: key)
    }

    static func setData(_ data: Data?, forKey key: String) {
        if let data {
            defaults?.set(data, forKey: key)
        } else {
            defaults?.removeObject(forKey: key)
        }
    }
}
