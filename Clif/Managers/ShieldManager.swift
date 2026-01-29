import Foundation
import ManagedSettings
import FamilyControls

/// Observable state wrapper for shield status.
/// Use this in SwiftUI views to reactively update when shield state changes.
@Observable
final class ShieldState {
    static let shared = ShieldState()

    private(set) var isActive: Bool = SharedDefaults.isShieldActive
    private(set) var currentBreakType: BreakType? = SharedDefaults.activeBreakType

    private init() {}

    /// Call this after any shield state change to update observers.
    func refresh() {
        isActive = SharedDefaults.isShieldActive
        currentBreakType = SharedDefaults.activeBreakType
    }
}

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
    /// - Parameter setUsageFlags: If true, sets isShieldActive and shieldActivatedAt for break tracking.
    ///   Set to false for Day Start Shield (no break tracking needed).
    /// - Returns: false if tokens couldn't be loaded.
    @discardableResult
    func activateFromStoredTokens(setUsageFlags: Bool = true) -> Bool {
        guard let appTokens = SharedDefaults.loadApplicationTokens(),
              let catTokens = SharedDefaults.loadCategoryTokens() else {
            #if DEBUG
            print("[ShieldManager] Failed to load tokens")
            #endif
            return false
        }
        let webTokens = SharedDefaults.loadWebDomainTokens() ?? Set()

        activate(applications: appTokens, categories: catTokens, webDomains: webTokens)

        if setUsageFlags {
            SharedDefaults.isShieldActive = true
            SharedDefaults.shieldActivatedAt = Date()
            SharedDefaults.synchronize()
        }

        #if DEBUG
        print("[ShieldManager] Shield activated (usageFlags: \(setUsageFlags))")
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
        ShieldState.shared.refresh()
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
    /// - Parameter success: For committed breaks, false if ended early (before planned duration).
    func toggle(success: Bool = true) {
        if SharedDefaults.isShieldActive {
            turnOff(success: success)
        } else {
            turnOn(breakType: .free, durationMinutes: nil)
        }
    }

    /// Turns on shield with specified break type and optional duration.
    /// - Parameters:
    ///   - breakType: The type of break (free or committed)
    ///   - durationMinutes: For committed breaks: positive = minutes, -1 = until 0%, -2 = until end of day. Nil for free.
    func turnOn(breakType: BreakType, durationMinutes: Int?) {
        #if DEBUG
        print("[ShieldManager] turnOn: breakType=\(breakType), duration=\(String(describing: durationMinutes))")
        #endif

        // Stop monitoring while shield is active (no need to track time during break)
        ScreenTimeManager.shared.stopMonitoring()

        guard activateFromStoredTokens() else { return }

        // Store break type and duration
        SharedDefaults.activeBreakType = breakType
        SharedDefaults.committedBreakDuration = durationMinutes

        // Log break started
        if let petId = SharedDefaults.monitoredPetId {
            let breakTypePayload: BreakTypePayload = switch breakType {
            case .free: .free
            case .committed: .committed(plannedMinutes: durationMinutes ?? 0)
            case .safety: .safety
            }
            SnapshotLogging.logBreakStarted(
                petId: petId,
                windPoints: SharedDefaults.monitoredWindPoints,
                breakType: breakTypePayload
            )
        }

        ShieldState.shared.refresh()
    }

    private func turnOff(success: Bool) {
        #if DEBUG
        print("[ShieldManager] toggle: OFF (success: \(success))")
        #endif

        // Only apply break reduction for successful breaks
        // Failed committed breaks (violation) don't reduce wind - pet is blown away
        if success {
            applyBreakReduction()
        }

        // Log break ended after reduction (uses updated windPoints), before resetting flags (need shieldActivatedAt)
        logBreakEnded(success: success)

        deactivateStore()
        SharedDefaults.resetShieldFlags()

        // Restart monitoring to resume wind tracking
        ScreenTimeManager.shared.restartMonitoring()

        ShieldState.shared.refresh()
    }

    // MARK: - Break Reduction

    /// Calculates break reduction based on shield duration and adds to totalBreakReduction.
    /// Also recalculates wind using SharedDefaults.calculatedWind.
    private func applyBreakReduction() {
        guard let activatedAt = SharedDefaults.shieldActivatedAt else { return }

        let elapsedSeconds = Date().timeIntervalSince(activatedAt)
        let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
        let fallRate = SharedDefaults.monitoredFallRate

        // fallRate is in pts/sec, limit is 100 pts
        // secondsForgiven = elapsedSeconds * fallRate * limitSeconds / 100
        // Use ceil to ensure even short breaks reduce wind (matches effectiveWind display)
        let secondsForgiven = Int(ceil(elapsedSeconds * fallRate * Double(limitSeconds) / 100.0))

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
        print("[ShieldManager] Break reduction: +\(secondsForgiven)s (elapsed: \(String(format: "%.1f", elapsedSeconds))s, fallRate: \(fallRate), total: \(newReduction)s\(wasCapped ? " [CAPPED]" : ""))")
        print("[ShieldManager] Wind recalculated: \(String(format: "%.1f", oldWind)) -> \(String(format: "%.1f", newWind))% (cumulative: \(cumulativeSeconds)s, effective: \(effectiveSeconds)s)")
        #endif
    }

    // MARK: - Break Logging

    /// Logs breakEnded event to SnapshotStore.
    /// Called when shield is turned off (break ends).
    private func logBreakEnded(success: Bool) {
        guard let petId = SharedDefaults.monitoredPetId,
              let activatedAt = SharedDefaults.shieldActivatedAt else { return }

        let actualMinutes = Int(Date().timeIntervalSince(activatedAt) / 60)

        SnapshotLogging.logBreakEnded(
            petId: petId,
            windPoints: SharedDefaults.monitoredWindPoints,
            actualMinutes: actualMinutes,
            success: success
        )
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

        // Log break ended after reduction (uses updated windPoints), before resetting flags (need shieldActivatedAt)
        logBreakEnded(success: true)

        deactivateStore()
        SharedDefaults.resetShieldFlags()

        #if DEBUG
        print("  After break reduction: wind=\(SharedDefaults.monitoredWindPoints)")
        #endif

        // Restart monitoring to resume wind tracking
        ScreenTimeManager.shared.restartMonitoring()

        ShieldState.shared.refresh()
    }

    // MARK: - Safety Shield Unlock

    enum SafetyUnlockResult {
        case safe       // wind < 80%, no penalty
        case blownAway  // wind >= 80%, pet lost
    }

    /// Whether the current safety shield can be safely unlocked (wind < 80%).
    var isSafetyUnlockSafe: Bool {
        SharedDefaults.effectiveWind < 80
    }

    /// Processes safety shield unlock. Returns whether the unlock is safe or results in blow away.
    @discardableResult
    func processSafetyShieldUnlock() -> SafetyUnlockResult {
        guard SharedDefaults.activeBreakType == .safety else {
            processUnlock()
            return .safe
        }

        applyBreakReduction()

        // After applyBreakReduction(), monitoredWindPoints is the final value
        let currentWind = SharedDefaults.monitoredWindPoints
        let result: SafetyUnlockResult = currentWind < 80 ? .safe : .blownAway

        logBreakEnded(success: result == .safe)
        deactivateStore()
        SharedDefaults.resetShieldFlags()

        // Restart monitoring to resume wind tracking
        ScreenTimeManager.shared.restartMonitoring()

        ShieldState.shared.refresh()

        return result
    }
}
