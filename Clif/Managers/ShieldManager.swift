import Foundation
import ManagedSettings
import FamilyControls
import DeviceActivity

/// Manages shield activation, deactivation, breaks, and cooldown logic.
/// Single source of truth for all shield-related operations.
final class ShieldManager {
    static let shared = ShieldManager()

    private let store = ManagedSettingsStore()
    private let center = DeviceActivityCenter()

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
        restartMonitoring()
    }

    // MARK: - Break Reduction

    /// Calculates break reduction based on shield duration and adds to totalBreakReduction.
    /// Also recalculates wind using WindCalculator.
    private func applyBreakReduction() {
        guard let activatedAt = SharedDefaults.shieldActivatedAt else { return }

        let elapsedSeconds = Int(Date().timeIntervalSince(activatedAt))
        let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
        let fallRate = SharedDefaults.monitoredFallRate

        // fallRate is in pts/sec, limit is 100 pts
        // secondsForgiven = elapsedSeconds * fallRate * limitSeconds / 100
        let secondsForgiven = Int(Double(elapsedSeconds) * fallRate * Double(limitSeconds) / 100.0)

        let oldReduction = SharedDefaults.totalBreakReduction
        let newReduction = oldReduction + secondsForgiven
        SharedDefaults.totalBreakReduction = newReduction

        // Recalculate wind using WindCalculator
        let oldWind = SharedDefaults.monitoredWindPoints
        let newWind = WindCalculator.currentWind()
        SharedDefaults.monitoredWindPoints = newWind

        #if DEBUG
        let cumulativeSeconds = SharedDefaults.monitoredLastThresholdSeconds
        let effectiveSeconds = max(0, cumulativeSeconds - newReduction)
        print("[ShieldManager] Break reduction: +\(secondsForgiven)s (elapsed: \(elapsedSeconds)s, fallRate: \(fallRate), total: \(newReduction)s)")
        print("[ShieldManager] Wind recalculated: \(String(format: "%.1f", oldWind)) -> \(String(format: "%.1f", newWind))% (cumulative: \(cumulativeSeconds)s, effective: \(effectiveSeconds)s)")
        #endif
    }

    // MARK: - Cooldown

    /// Starts shield cooldown - shield won't auto-activate for specified duration.
    /// This allows wind to rise to 105%+ for blow-away if user continues using apps.
    func startCooldown(seconds: TimeInterval = 30) {
        SharedDefaults.shieldCooldownUntil = Date().addingTimeInterval(seconds)
        #if DEBUG
        print("[ShieldManager] Cooldown set for \(seconds)s")
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

        #if DEBUG
        print("  After break reduction: wind=\(SharedDefaults.monitoredWindPoints)")
        #endif

        restartMonitoring()
    }

    // MARK: - Monitoring Restart

    /// Restarts monitoring with new thresholds after break.
    /// Called after shield deactivation to regenerate thresholds that account for
    /// the updated totalBreakReduction value.
    private func restartMonitoring() {
        guard let petId = SharedDefaults.monitoredPetId else {
            #if DEBUG
            print("[ShieldManager] restartMonitoring: No monitored pet")
            #endif
            return
        }

        guard let appTokens = SharedDefaults.loadApplicationTokens(),
              let catTokens = SharedDefaults.loadCategoryTokens() else {
            #if DEBUG
            print("[ShieldManager] restartMonitoring: Failed to load tokens")
            #endif
            return
        }

        let webTokens = SharedDefaults.loadWebDomainTokens() ?? Set()

        guard !appTokens.isEmpty || !catTokens.isEmpty else {
            #if DEBUG
            print("[ShieldManager] restartMonitoring: No tokens to monitor")
            #endif
            return
        }

        let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let events = MonitoringEventBuilder.buildEvents(
            limitSeconds: limitSeconds,
            appTokens: appTokens,
            catTokens: catTokens,
            webTokens: webTokens
        )

        let activityName = DeviceActivityName.forPet(petId)

        do {
            let existingActivities = center.activities
            if !existingActivities.isEmpty {
                center.stopMonitoring(existingActivities)
            }

            try center.startMonitoring(activityName, during: schedule, events: events)

            #if DEBUG
            print("[ShieldManager] restartMonitoring: SUCCESS - \(events.count) events")
            #endif
        } catch {
            #if DEBUG
            print("[ShieldManager] restartMonitoring: FAILED - \(error.localizedDescription)")
            #endif
        }
    }
}

// MARK: - Monitoring Event Builder

/// Helper for building DeviceActivity threshold events.
/// Extracted to be reusable by both ShieldManager and ScreenTimeManager.
enum MonitoringEventBuilder {

    /// Builds threshold events for monitoring.
    ///
    /// Always generates thresholds from 0s to limit+buffer.
    /// iOS automatically ignores thresholds that have already been passed.
    static func buildEvents(
        limitSeconds: Int,
        appTokens: Set<ApplicationToken>,
        catTokens: Set<ActivityCategoryToken>,
        webTokens: Set<WebDomainToken>
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        let maxThresholds = AppConstants.maxThresholds
        let minInterval = AppConstants.minimumThresholdSeconds

        // Add 10% buffer for blow-away detection (110%)
        let targetSeconds = limitSeconds + max(limitSeconds / 10, minInterval)

        // Calculate interval to spread thresholds evenly across full range
        let intervalSeconds = max(targetSeconds / maxThresholds, minInterval)

        #if DEBUG
        print("[MonitoringEventBuilder] buildEvents:")
        print("  limitSeconds: \(limitSeconds)s")
        print("  targetSeconds (with buffer): \(targetSeconds)s")
        print("  intervalSeconds: \(intervalSeconds)s")
        #endif

        // Generate thresholds from first interval to cover full range
        // iOS ignores already-passed thresholds automatically
        var currentSeconds = intervalSeconds

        while events.count < maxThresholds {
            let eventName = DeviceActivityEvent.Name("second_\(currentSeconds)")
            let minutes = currentSeconds / 60
            let seconds = currentSeconds % 60

            events[eventName] = DeviceActivityEvent(
                applications: appTokens,
                categories: catTokens,
                webDomains: webTokens,
                threshold: DateComponents(minute: minutes, second: seconds)
            )

            currentSeconds += intervalSeconds
        }

        #if DEBUG
        print("  Created \(events.count) events")
        if let firstKey = events.keys.min(by: { $0.rawValue < $1.rawValue }) {
            print("  First threshold: \(firstKey.rawValue)")
        }
        if let lastKey = events.keys.max(by: { $0.rawValue < $1.rawValue }) {
            print("  Last threshold: \(lastKey.rawValue)")
        }
        #endif

        return events
    }
}
