import Foundation
import ManagedSettings
import FamilyControls

/// Manages shield activation, deactivation, breaks, and cooldown logic.
/// Single source of truth for all shield-related operations.
///
/// Monitoring is delegated to ScreenTimeManager.
final class ShieldManager {
    static let shared = ShieldManager()

    private let store = ManagedSettingsStore()

    private init() {}

    // MARK: - Shield Activation

    /// Activates shield for specific tokens.
    func activate(
        applications: Set<ApplicationToken>,
        categories: Set<ActivityCategoryToken>,
        webDomains: Set<WebDomainToken>
    ) {
        if !applications.isEmpty {
            store.shield.applications = applications
        }
        if !categories.isEmpty {
            store.shield.applicationCategories = .specific(categories, except: Set())
        }
        if !webDomains.isEmpty {
            store.shield.webDomains = webDomains
        }
    }

    /// Activates shield using currently stored tokens.
    /// Returns false if tokens couldn't be loaded.
    @discardableResult
    func activateFromStoredTokens() -> Bool {
        guard let appTokens = SharedDefaults.loadApplicationTokens(),
              let catTokens = SharedDefaults.loadCategoryTokens() else {
            #if DEBUG
            print("[ShieldManager] Failed to load tokens")
            #endif
            return false
        }
        let webTokens = SharedDefaults.loadWebDomainTokens() ?? Set()

        activate(applications: appTokens, categories: catTokens, webDomains: webTokens)

        SharedDefaults.isShieldActive = true
        SharedDefaults.shieldActivatedAt = Date()
        SharedDefaults.synchronize()

        #if DEBUG
        print("[ShieldManager] Shield activated at \(Date())")
        #endif

        return true
    }

    // MARK: - Shield Deactivation

    /// Clears shield from ManagedSettingsStore and resets all shield flags.
    func clear() {
        #if DEBUG
        print("[ShieldManager] clear() called")
        #endif
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        SharedDefaults.resetShieldFlags()
    }

    /// Deactivates shield (clears store) without resetting other flags.
    /// Used internally when we need to clear shield but manage flags separately.
    private func deactivateStore() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    // MARK: - Shield Toggle (from UI)

    /// Toggles shield on/off from the home screen button.
    /// When turning ON: activates shield for monitored tokens, records activation time.
    /// When turning OFF: calculates break reduction, clears shield, starts cooldown.
    func toggle() {
        if SharedDefaults.isShieldActive {
            turnOff()
        } else {
            turnOn()
        }
    }

    private func turnOn() {
        #if DEBUG
        print("[ShieldManager] toggle: ON")
        #endif

        // Stop monitoring while shield is active (no need to track time during break)
        ScreenTimeManager.shared.stopMonitoring()

        guard activateFromStoredTokens() else { return }
    }

    private func turnOff() {
        #if DEBUG
        print("[ShieldManager] toggle: OFF")
        #endif

        applyBreakReduction()
        deactivateStore()
        SharedDefaults.resetShieldFlags()

        startCooldown()

        // Restart monitoring to resume wind tracking
        ScreenTimeManager.shared.restartMonitoring()
    }

    // MARK: - Break Reduction

    /// Calculates break reduction based on shield duration and adds to totalBreakReduction.
    /// Also recalculates wind using SharedDefaults.calculatedWind.
    private func applyBreakReduction() {
        guard let activatedAt = SharedDefaults.shieldActivatedAt else { return }

        let elapsedSeconds = Int(Date().timeIntervalSince(activatedAt))
        let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
        let fallRate = SharedDefaults.monitoredFallRate

        // fallRate is in pts/sec, limit is 100 pts
        // secondsForgiven = elapsedSeconds * fallRate * limitSeconds / 100
        let secondsForgiven = Int(Double(elapsedSeconds) * fallRate * Double(limitSeconds) / 100.0)

        let oldReduction = SharedDefaults.totalBreakReduction
        let cumulativeSeconds = SharedDefaults.totalCumulativeSeconds

        // Cap break reduction at cumulative seconds - can't "save up" more than actually used
        let newReduction = min(oldReduction + secondsForgiven, cumulativeSeconds)
        SharedDefaults.totalBreakReduction = newReduction

        // Recalculate wind using SharedDefaults
        let oldWind = SharedDefaults.monitoredWindPoints
        let newWind = SharedDefaults.calculatedWind
        SharedDefaults.monitoredWindPoints = newWind

        #if DEBUG
        let effectiveSeconds = max(0, cumulativeSeconds - newReduction)
        let wasCapped = oldReduction + secondsForgiven > cumulativeSeconds
        print("[ShieldManager] Break reduction: +\(secondsForgiven)s (elapsed: \(elapsedSeconds)s, fallRate: \(fallRate), total: \(newReduction)s\(wasCapped ? " [CAPPED]" : ""))")
        print("[ShieldManager] Wind recalculated: \(String(format: "%.1f", oldWind)) -> \(String(format: "%.1f", newWind))% (cumulative: \(cumulativeSeconds)s, effective: \(effectiveSeconds)s)")
        #endif
    }

    // MARK: - Cooldown

    /// Starts shield cooldown - shield won't auto-activate for specified duration.
    /// Duration is 2× buffer time (10% of limit) to allow wind to rise from ~95% to 105%+ for blow-away.
    /// After unlock, wind is typically around 95% (due to fallRate during shield).
    /// User needs to gain ~10% wind to reach blow-away threshold.
    func startCooldown() {
        #if DEBUG
        // Debug: fixed 30s cooldown for testing with short limits
        let cooldownSeconds: TimeInterval = 30
        #else
        // Production: 10% of limit (2× buffer)
        let cooldownSeconds = TimeInterval(SharedDefaults.bufferSeconds * 2)
        #endif
        SharedDefaults.shieldCooldownUntil = Date().addingTimeInterval(cooldownSeconds)
        #if DEBUG
        print("[ShieldManager] Cooldown set for \(cooldownSeconds)s")
        #endif
    }

    // MARK: - Unlock Processing

    /// Processes unlock request from shield deep link.
    /// Called when user taps unlock notification from ShieldAction.
    func processUnlock() {
        #if DEBUG
        print("[ShieldManager] processUnlock() called")
        print("  Before: wind=\(SharedDefaults.monitoredWindPoints), lastThreshold=\(SharedDefaults.monitoredLastThresholdSeconds)")
        #endif

        guard SharedDefaults.monitoredPetId != nil else {
            #if DEBUG
            print("[ShieldManager] processUnlock: No monitored pet, just clearing shields")
            #endif
            clear()
            return
        }

        applyBreakReduction()
        deactivateStore()
        SharedDefaults.resetShieldFlags()

        startCooldown()

        #if DEBUG
        print("  After break reduction: wind=\(SharedDefaults.monitoredWindPoints)")
        #endif

        // Restart monitoring to resume wind tracking
        ScreenTimeManager.shared.restartMonitoring()
    }
}
