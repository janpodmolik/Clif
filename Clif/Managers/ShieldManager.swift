import Foundation
import ManagedSettings
import FamilyControls

/// Observable state wrapper for shield status.
/// Use this in SwiftUI views to reactively update when shield state changes.
@Observable
final class ShieldState {
    static let shared = ShieldState()

    private(set) var currentBreakType: BreakType? = SharedDefaults.activeBreakType

    var isActive: Bool { currentBreakType != nil }

    private init() {}

    /// Call this after any shield state change to update observers.
    func refresh() {
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

    /// Activates shield in ManagedSettingsStore using stored tokens.
    /// Does NOT set break-tracking flags — use for Day Start Shield or store-only activation.
    @discardableResult
    func activateStoreFromStoredTokens() -> Bool {
        let appTokens = SharedDefaults.loadApplicationTokens() ?? []
        let catTokens = SharedDefaults.loadCategoryTokens() ?? []
        let webTokens = SharedDefaults.loadWebDomainTokens() ?? []

        guard !appTokens.isEmpty || !catTokens.isEmpty || !webTokens.isEmpty else {
            #if DEBUG
            print("[ShieldManager] No tokens to activate")
            #endif
            return false
        }

        activate(applications: appTokens, categories: catTokens, webDomains: webTokens)
        return true
    }

    // MARK: - Shield Deactivation

    /// Clears shield from ManagedSettingsStore and resets all shield flags.
    func clear() {
        #if DEBUG
        print("[ShieldManager] clear() called")
        #endif
        deactivateStore()
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
        assert(breakType != .safety, "[ShieldManager] turnOn should not be called with .safety — safety shield is activated by DeviceActivityMonitor extension")

        #if DEBUG
        print("[ShieldManager] turnOn: breakType=\(breakType), duration=\(String(describing: durationMinutes))")
        #endif

        // Stop monitoring while shield is active (no need to track time during break)
        ScreenTimeManager.shared.stopMonitoring()

        guard activateStoreFromStoredTokens() else { return }

        // Store break type and duration (activeBreakType setter syncs isShieldActive)
        SharedDefaults.shieldActivatedAt = Date()
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

    func turnOff(success: Bool) {
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

        // Recalculate wind from updated reduction
        let newWind = SharedDefaults.calculatedWind

        #if DEBUG
        let oldWind = SharedDefaults.monitoredWindPoints
        #endif

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
        guard SharedDefaults.monitoredPetId != nil else {
            clear()
            return
        }

        turnOff(success: true)
    }

    // MARK: - Safety Shield Unlock

    enum SafetyUnlockResult {
        case safe       // wind below high threshold, no penalty
        case blownAway  // wind at or above high threshold, pet lost
    }

    /// Whether the current safety shield can be safely unlocked (wind below high threshold).
    var isSafetyUnlockSafe: Bool {
        SharedDefaults.effectiveWind < WindLevel.high.threshold
    }

    /// Processes safety shield unlock. Returns whether the unlock is safe or results in blow away.
    @discardableResult
    func processSafetyShieldUnlock() -> SafetyUnlockResult {
        guard SharedDefaults.activeBreakType == .safety else {
            assertionFailure("[ShieldManager] processSafetyShieldUnlock called with non-safety break type: \(String(describing: SharedDefaults.activeBreakType))")
            processUnlock()
            return .safe
        }

        applyBreakReduction()

        // Use monitoredWindPoints (updated by applyBreakReduction) as the source of truth
            let result: SafetyUnlockResult = SharedDefaults.monitoredWindPoints < WindLevel.high.threshold ? .safe : .blownAway

        logBreakEnded(success: result == .safe)
        deactivateStore()
        SharedDefaults.resetShieldFlags()

        // Restart monitoring to resume wind tracking
        ScreenTimeManager.shared.restartMonitoring()

        ShieldState.shared.refresh()

        return result
    }
}
