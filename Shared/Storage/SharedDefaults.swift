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
    
    // MARK: - Per-Pet Token Storage

    private static func tokenKey(_ petId: UUID, _ suffix: String) -> String {
        "pet_\(petId.uuidString)_\(suffix)"
    }

    /// Saves tokens for a specific pet.
    static func saveTokens(
        petId: UUID,
        applications: Set<ApplicationToken>,
        categories: Set<ActivityCategoryToken>,
        webDomains: Set<WebDomainToken>
    ) {
        defaults?.set(try? PropertyListEncoder().encode(applications), forKey: tokenKey(petId, "appTokens"))
        defaults?.set(try? PropertyListEncoder().encode(categories), forKey: tokenKey(petId, "catTokens"))
        defaults?.set(try? PropertyListEncoder().encode(webDomains), forKey: tokenKey(petId, "webTokens"))

        // Also save to active keys for extension access
        defaults?.set(try? PropertyListEncoder().encode(applications), forKey: DefaultsKeys.applicationTokens)
        defaults?.set(try? PropertyListEncoder().encode(categories), forKey: DefaultsKeys.categoryTokens)
        defaults?.set(try? PropertyListEncoder().encode(webDomains), forKey: DefaultsKeys.webDomainTokens)
    }

    /// Clears tokens for a specific pet.
    static func clearTokens(petId: UUID) {
        // Clear per-pet keys
        defaults?.removeObject(forKey: tokenKey(petId, "appTokens"))
        defaults?.removeObject(forKey: tokenKey(petId, "catTokens"))
        defaults?.removeObject(forKey: tokenKey(petId, "webTokens"))

        // Also clear active token keys used by extensions
        defaults?.removeObject(forKey: DefaultsKeys.applicationTokens)
        defaults?.removeObject(forKey: DefaultsKeys.categoryTokens)
        defaults?.removeObject(forKey: DefaultsKeys.webDomainTokens)
    }

    /// Loads application tokens for a specific pet.
    static func loadApplicationTokens(petId: UUID) -> Set<ApplicationToken>? {
        guard let data = defaults?.data(forKey: tokenKey(petId, "appTokens")) else { return nil }
        return try? PropertyListDecoder().decode(Set<ApplicationToken>.self, from: data)
    }

    /// Loads category tokens for a specific pet.
    static func loadCategoryTokens(petId: UUID) -> Set<ActivityCategoryToken>? {
        guard let data = defaults?.data(forKey: tokenKey(petId, "catTokens")) else { return nil }
        return try? PropertyListDecoder().decode(Set<ActivityCategoryToken>.self, from: data)
    }

    /// Loads web domain tokens for a specific pet.
    static func loadWebDomainTokens(petId: UUID) -> Set<WebDomainToken>? {
        guard let data = defaults?.data(forKey: tokenKey(petId, "webTokens")) else { return nil }
        return try? PropertyListDecoder().decode(Set<WebDomainToken>.self, from: data)
    }

    // MARK: - Active Token Access (used by extensions)

    /// Loads application tokens for the currently monitored pet.
    static func loadApplicationTokens() -> Set<ApplicationToken>? {
        defaults?.synchronize()
        guard let data = defaults?.data(forKey: DefaultsKeys.applicationTokens) else {
            logTokenDebug("loadApplicationTokens: no data found")
            return nil
        }
        do {
            let tokens = try PropertyListDecoder().decode(Set<ApplicationToken>.self, from: data)
            logTokenDebug("loadApplicationTokens: decoded \(tokens.count) tokens from \(data.count) bytes")
            return tokens
        } catch {
            logTokenDebug("loadApplicationTokens: decode FAILED - \(error)")
            return nil
        }
    }

    /// Loads category tokens for the currently monitored pet.
    static func loadCategoryTokens() -> Set<ActivityCategoryToken>? {
        defaults?.synchronize()
        guard let data = defaults?.data(forKey: DefaultsKeys.categoryTokens) else {
            logTokenDebug("loadCategoryTokens: no data found")
            return nil
        }
        do {
            let tokens = try PropertyListDecoder().decode(Set<ActivityCategoryToken>.self, from: data)
            logTokenDebug("loadCategoryTokens: decoded \(tokens.count) tokens from \(data.count) bytes")
            return tokens
        } catch {
            logTokenDebug("loadCategoryTokens: decode FAILED - \(error)")
            return nil
        }
    }

    /// Loads web domain tokens for the currently monitored pet.
    static func loadWebDomainTokens() -> Set<WebDomainToken>? {
        defaults?.synchronize()
        guard let data = defaults?.data(forKey: DefaultsKeys.webDomainTokens) else {
            logTokenDebug("loadWebDomainTokens: no data found")
            return nil
        }
        do {
            let tokens = try PropertyListDecoder().decode(Set<WebDomainToken>.self, from: data)
            logTokenDebug("loadWebDomainTokens: decoded \(tokens.count) tokens from \(data.count) bytes")
            return tokens
        } catch {
            logTokenDebug("loadWebDomainTokens: decode FAILED - \(error)")
            return nil
        }
    }

    private static func logTokenDebug(_ message: String) {
        ExtensionLogger.log(message, prefix: "[SharedDefaults]")
    }
    
    // MARK: - Monitoring Context (lightweight data for extensions to create snapshots)

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

    /// Timestamp when current break started (for calculating actualMinutes on break end).
    static var breakStartedAt: Date? {
        get { defaults?.object(forKey: DefaultsKeys.breakStartedAt) as? Date }
        set { defaults?.set(newValue, forKey: DefaultsKeys.breakStartedAt) }
    }


    // MARK: - Sync

    /// Number of snapshot events already synced to backend.
    /// Used for incremental sync - only events after this offset are sent.
    static var snapshotSyncOffset: Int {
        get { defaults?.integer(forKey: DefaultsKeys.snapshotSyncOffset) ?? 0 }
        set { defaults?.set(newValue, forKey: DefaultsKeys.snapshotSyncOffset) }
    }

    // MARK: - Limit Settings

    /// User-configurable shield and notification settings.
    static var limitSettings: LimitSettings {
        get {
            guard let data = defaults?.data(forKey: DefaultsKeys.limitSettings),
                  let settings = try? JSONDecoder().decode(LimitSettings.self, from: data) else {
                return .default
            }
            return settings
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults?.set(data, forKey: DefaultsKeys.limitSettings)
            }
        }
    }

    /// Whether morning shield is currently active (set at day reset, cleared on preset selection).
    /// Note: Uses fresh UserDefaults instance for reads to ensure cross-process sync.
    static var isMorningShieldActive: Bool {
        get {
            let fresh = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
            return fresh?.bool(forKey: DefaultsKeys.isMorningShieldActive) ?? false
        }
        set {
            defaults?.set(newValue, forKey: DefaultsKeys.isMorningShieldActive)
            defaults?.synchronize()
        }
    }

    /// Whether wind preset is locked for today (after first unlock or selection).
    static var windPresetLockedForToday: Bool {
        get { defaults?.bool(forKey: DefaultsKeys.windPresetLockedForToday) ?? false }
        set { defaults?.set(newValue, forKey: DefaultsKeys.windPresetLockedForToday) }
    }

    /// Date when preset was locked (for day boundary checking).
    static var windPresetLockedDate: Date? {
        get { defaults?.object(forKey: DefaultsKeys.windPresetLockedDate) as? Date }
        set { defaults?.set(newValue, forKey: DefaultsKeys.windPresetLockedDate) }
    }

    /// Today's selected preset (nil if not yet selected).
    static var todaySelectedPreset: String? {
        get { defaults?.string(forKey: DefaultsKeys.todaySelectedPreset) }
        set { defaults?.set(newValue, forKey: DefaultsKeys.todaySelectedPreset) }
    }

    /// Last known WindLevel (for detecting level changes in extension).
    static var lastKnownWindLevel: Int {
        get { defaults?.integer(forKey: DefaultsKeys.lastKnownWindLevel) ?? 0 }
        set { defaults?.set(newValue, forKey: DefaultsKeys.lastKnownWindLevel) }
    }

    /// Whether shield is currently active (wind should not increase while true).
    /// Note: Uses fresh UserDefaults instance for reads to ensure cross-process sync.
    static var isShieldActive: Bool {
        get {
            // Create fresh instance to bypass caching issues between processes
            let fresh = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
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

    /// Fall rate in points per second (set by main app from preset).
    /// Used to calculate wind decrease while shield is active.
    static var monitoredFallRate: Double {
        get { defaults?.double(forKey: DefaultsKeys.monitoredFallRate) ?? 0 }
        set { defaults?.set(newValue, forKey: DefaultsKeys.monitoredFallRate) }
    }

    /// Timestamp of last unlock (for shield cooldown).
    /// Set by main app when user unlocks shield.
    static var lastUnlockAt: Date? {
        get {
            // Create fresh instance to bypass caching issues between processes
            let fresh = UserDefaults(suiteName: AppConstants.appGroupIdentifier)
            return fresh?.object(forKey: DefaultsKeys.lastUnlockAt) as? Date
        }
        set {
            defaults?.set(newValue, forKey: DefaultsKeys.lastUnlockAt)
            defaults?.synchronize()
        }
    }

    // MARK: - Helpers

    /// Forces synchronization of UserDefaults (important for cross-process communication).
    static func synchronize() {
        defaults?.synchronize()
    }

    /// Resets all shield-related flags to allow wind tracking.
    /// Call this when starting fresh monitoring or clearing shields.
    static func resetShieldFlags() {
        #if DEBUG
        print("DEBUG: resetShieldFlags() called - before: isShieldActive=\(isShieldActive), isMorningShieldActive=\(isMorningShieldActive)")
        #endif
        isShieldActive = false
        isMorningShieldActive = false
        shieldActivatedAt = nil
        synchronize()
        #if DEBUG
        print("DEBUG: resetShieldFlags() called - after: isShieldActive=\(isShieldActive), isMorningShieldActive=\(isMorningShieldActive)")
        #endif
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

    static func removeObject(forKey key: String) {
        defaults?.removeObject(forKey: key)
    }

    static func integer(forKey key: String) -> Int {
        defaults?.integer(forKey: key) ?? 0
    }

    static func setInt(_ value: Int, forKey key: String) {
        defaults?.set(value, forKey: key)
    }

    static func bool(forKey key: String) -> Bool {
        defaults?.bool(forKey: key) ?? false
    }

    static func set(_ value: Bool, forKey key: String) {
        defaults?.set(value, forKey: key)
    }
}
