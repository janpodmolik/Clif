import Foundation

/// Shared UserDefaults wrapper for communication between main app and extensions.
/// Uses App Group container for cross-process data sharing.
///
/// Extensions:
/// - SharedDefaults+Tokens.swift - Token storage for FamilyControls
/// - SharedDefaults+Shield.swift - Shield state and cooldown
/// - SharedDefaults+Wind.swift - Wind points and monitoring context
/// - SharedDefaults+DayState.swift - Daily presets and day start shield
/// - SharedDefaults+Coins.swift - Currency balance storage
struct SharedDefaults {

    // MARK: - Shared Storage

    static let defaults: UserDefaults? = {
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

    // MARK: - Misc

    static var lastMonitorUpdate: Date? {
        get { defaults?.object(forKey: DefaultsKeys.lastMonitorUpdate) as? Date }
        set { defaults?.set(newValue, forKey: DefaultsKeys.lastMonitorUpdate) }
    }

    // MARK: - Authorization

    /// Tracks if user ever granted Screen Time authorization.
    /// Used to detect revocation: if wasEverAuthorized && status == .notDetermined → revoked.
    static var wasEverAuthorized: Bool {
        get { defaults?.bool(forKey: DefaultsKeys.wasEverAuthorized) ?? false }
        set { defaults?.set(newValue, forKey: DefaultsKeys.wasEverAuthorized) }
    }

    // MARK: - Post-Reinstall Reselection

    /// Persisted flag for post-reinstall app reselection state.
    /// Survives app restart (but not reinstall, which is correct — fresh install = no pet).
    /// Set to true when reinstall is detected, cleared after successful reselection.
    static var needsAppReselection: Bool {
        get { defaults?.bool(forKey: DefaultsKeys.needsAppReselection) ?? false }
        set { defaults?.set(newValue, forKey: DefaultsKeys.needsAppReselection) }
    }

    // MARK: - Sync

    /// Forces synchronization of UserDefaults (important for cross-process communication).
    static func synchronize() {
        defaults?.synchronize()
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
