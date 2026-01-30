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
    private var breakCompletionTimer: Timer?

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
        stopBreakCompletionMonitoring()
        BreakNotification.cancelScheduledCommittedBreakEnd()
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
        let now = Date()
        SharedDefaults.shieldActivatedAt = now
        SharedDefaults.activeBreakType = breakType
        SharedDefaults.committedBreakDuration = durationMinutes

        // Schedule notification for committed break end
        if breakType == .committed, let minutes = durationMinutes {
            let seconds: TimeInterval = minutes == 0 ? 20 : TimeInterval(minutes * 60)
            let fireDate = now.addingTimeInterval(seconds)
            BreakNotification.scheduleCommittedBreakEnd(at: fireDate)
        }

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
        startBreakCompletionMonitoring()
    }

    func turnOff(success: Bool) {
        stopBreakCompletionMonitoring()
        #if DEBUG
        print("[ShieldManager] toggle: OFF (success: \(success))")
        #endif

        // Cancel any scheduled break end notification
        BreakNotification.cancelScheduledCommittedBreakEnd()

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

    // MARK: - Break Completion Monitoring

    private func startBreakCompletionMonitoring() {
        breakCompletionTimer?.invalidate()
        breakCompletionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkBreakCompletion()
        }
    }

    private func stopBreakCompletionMonitoring() {
        breakCompletionTimer?.invalidate()
        breakCompletionTimer = nil
    }

    private func checkBreakCompletion() {
        guard SharedDefaults.isShieldActive,
              let breakType = SharedDefaults.activeBreakType,
              let activatedAt = SharedDefaults.shieldActivatedAt else { return }

        switch breakType {
        case .committed:
            let duration: TimeInterval? = SharedDefaults.committedBreakDuration.map {
                $0 == 0 ? TimeInterval(20) : TimeInterval($0 * 60)
            }
            if let duration, Date().timeIntervalSince(activatedAt) >= duration {
                turnOff(success: true)
            }

        case .free:
            if !SharedDefaults.windZeroNotified, SharedDefaults.effectiveWind <= 0 {
                SharedDefaults.windZeroNotified = true
                BreakNotification.freeBreakWindZero.send()
            }

        case .safety:
            if !SharedDefaults.windZeroNotified, SharedDefaults.effectiveWind <= 0 {
                SharedDefaults.windZeroNotified = true
                BreakNotification.safetyBreakWindZero.send()
            }
        }
    }

    // MARK: - Break Reduction

    /// Calculates break reduction based on shield duration and adds to totalBreakReduction.
    /// Also recalculates wind using SharedDefaults.calculatedWind.
    private func applyBreakReduction() {
        guard let activatedAt = SharedDefaults.shieldActivatedAt else { return }

        let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
        guard limitSeconds > 0 else { return }

        let fallRate = SharedDefaults.monitoredFallRate
        let elapsedSeconds = Date().timeIntervalSince(activatedAt)

        // Wind drop in points = elapsed * fallRate (same formula effectiveWind uses)
        let baseWind = SharedDefaults.monitoredWindPoints
        let windDrop = min(elapsedSeconds * fallRate, baseWind) // can't drop below 0
        let newWind = max(0, baseWind - windDrop)

        // Convert point drop to seconds forgiven: points / 100 * limitSeconds
        let secondsForgiven = Int(round(windDrop / 100.0 * Double(limitSeconds)))

        let oldReduction = SharedDefaults.totalBreakReduction
        let cumulativeSeconds = SharedDefaults.totalCumulativeSeconds

        // Cap break reduction at cumulative seconds - can't "save up" more than actually used
        let newReduction = min(oldReduction + secondsForgiven, cumulativeSeconds)
        SharedDefaults.totalBreakReduction = newReduction

        // Store the same wind value that effectiveWind was showing — no UI jump
        SharedDefaults.monitoredWindPoints = newWind

        #if DEBUG
        let effectiveSeconds = max(0, cumulativeSeconds - newReduction)
        let wasCapped = oldReduction + secondsForgiven > cumulativeSeconds
        print("[ShieldManager] Break reduction: +\(secondsForgiven)s (elapsed: \(String(format: "%.1f", elapsedSeconds))s, windDrop: \(String(format: "%.2f", windDrop))pts, total: \(newReduction)s\(wasCapped ? " [CAPPED]" : ""))")
        print("[ShieldManager] Wind recalculated: \(String(format: "%.1f", baseWind)) -> \(String(format: "%.1f", newWind))% (cumulative: \(cumulativeSeconds)s, effective: \(effectiveSeconds)s)")
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
