import Foundation

/// Configuration for internal testers (TestFlight builds).
/// Provides accelerated wind timing and evolution controls.
/// Active only on TestFlight — completely inert in App Store and simulator builds.
enum TesterConfig {
    private static let defaults = SharedDefaults.defaults
    private static let keyPrefix = "testerConfig_"

    // MARK: - TestFlight Detection

    /// True when running on a TestFlight build (sandbox receipt present, not simulator).
    static let isTestFlight: Bool = {
        #if targetEnvironment(simulator)
        return false
        #else
        guard let receiptURL = Bundle.main.appStoreReceiptURL else { return false }
        return receiptURL.lastPathComponent == "sandboxReceipt"
        #endif
    }()

    // MARK: - Override Toggle

    /// Whether tester wind overrides are active.
    /// Only effective when `isTestFlight` is true.
    static var isEnabled: Bool {
        get { defaults?.object(forKey: keyPrefix + "isEnabled") as? Bool ?? false }
        set { defaults?.set(newValue, forKey: keyPrefix + "isEnabled") }
    }

    /// Combined check: TestFlight build + user toggled override on.
    static var isActive: Bool {
        isTestFlight && isEnabled
    }

    // MARK: - Wind Rise

    /// Minutes of blocked app usage to reach blow away.
    /// Default: 2 minutes for quick testing.
    static var minutesToBlowAway: Double {
        get {
            let value = defaults?.double(forKey: keyPrefix + "minutesToBlowAway") ?? 0
            return value > 0 ? value : 2
        }
        set { defaults?.set(newValue, forKey: keyPrefix + "minutesToBlowAway") }
    }

    // MARK: - Wind Fall

    /// Minutes of break to fully recover.
    /// Default: 2 minutes for quick testing.
    static var minutesToRecover: Double {
        get {
            let value = defaults?.double(forKey: keyPrefix + "minutesToRecover") ?? 0
            return value > 0 ? value : 2
        }
        set { defaults?.set(newValue, forKey: keyPrefix + "minutesToRecover") }
    }

    // MARK: - Computed Rates

    static var riseRate: Double { 100 / minutesToBlowAway }
    static var fallRate: Double { 100 / minutesToRecover }
}
