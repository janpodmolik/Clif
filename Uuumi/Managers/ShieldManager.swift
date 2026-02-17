import Foundation
import ManagedSettings
import FamilyControls
import UIKit

/// Observable state wrapper for shield status.
/// Use this in SwiftUI views to reactively update when shield state changes.
@Observable
final class ShieldState {
    static let shared = ShieldState()

    private(set) var currentBreakType: BreakType? = SharedDefaults.activeBreakType
    private(set) var lastEarnedCoins: Int = 0

    var isActive: Bool { currentBreakType != nil }

    private init() {}

    /// Call this after any shield state change to update observers.
    func refresh() {
        currentBreakType = SharedDefaults.activeBreakType
    }

    func setEarnedCoins(_ amount: Int) {
        lastEarnedCoins = amount
    }

    func clearEarnedCoins() {
        lastEarnedCoins = 0
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

    private init() {
        // Listen for Darwin notification from DeviceActivityMonitor extension
        // when safety shield is activated while the app is in foreground.
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer else { return }
                let manager = Unmanaged<ShieldManager>.fromOpaque(observer).takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.handleSafetyShieldActivatedByExtension()
                }
            },
            DarwinNotifications.safetyShieldActivated as CFString,
            nil,
            .deliverImmediately
        )
    }

    /// Called when the extension activates safety shield and notifies via Darwin notification.
    /// Refreshes UI state and starts break completion monitoring.
    private func handleSafetyShieldActivatedByExtension() {
        guard SharedDefaults.activeBreakType == .safety else { return }
        WindReminderNotification.cancel { print($0) }
        ShieldState.shared.refresh()
        startBreakCompletionMonitoring()
    }

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
            processPendingCoins()
        } else {
            turnOn(breakType: .free, committedMode: nil)
        }
    }

    /// Turns on shield with specified break type and optional committed mode.
    /// - Parameters:
    ///   - breakType: The type of break (free or committed)
    ///   - committedMode: Mode for committed breaks. Nil for free breaks.
    ///   - startDate: When the break actually started. Defaults to now. Used by auto-lock to backdate the free break to when the committed break ended.
    func turnOn(breakType: BreakType, committedMode: CommittedBreakMode?, startDate: Date? = nil) {
        assert(breakType != .safety, "[ShieldManager] turnOn should not be called with .safety — safety shield is activated by DeviceActivityMonitor extension")

        #if DEBUG
        print("[ShieldManager] turnOn: breakType=\(breakType), mode=\(String(describing: committedMode))")
        #endif

        // Stop monitoring while shield is active (no need to track time during break)
        ScreenTimeManager.shared.stopMonitoring()

        guard activateStoreFromStoredTokens() else { return }

        // Store break type and mode (activeBreakType setter syncs isShieldActive)
        let now = startDate ?? Date()
        SharedDefaults.shieldActivatedAt = now
        SharedDefaults.activeBreakType = breakType
        SharedDefaults.committedBreakMode = committedMode

        // Schedule notification for committed break end
        if breakType == .committed, let mode = committedMode,
           SharedDefaults.limitSettings.notifications.shouldSendBreak(.committedBreakEnded) {
            let seconds: TimeInterval? = if let fixed = mode.durationSeconds {
                fixed
            } else if case .untilZeroWind = mode, SharedDefaults.monitoredFallRate > 0 {
                SharedDefaults.monitoredWindPoints / SharedDefaults.monitoredFallRate
            } else if case .untilEndOfDay = mode,
                      let midnight = Calendar.current.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime) {
                midnight.timeIntervalSince(now)
            } else {
                nil
            }
            if let seconds, seconds > 0 {
                BreakNotification.scheduleCommittedBreakEnd(at: now.addingTimeInterval(seconds))
            }
        }

        // Log break started
        if let petId = SharedDefaults.monitoredPetId {
            let plannedMinutes: Int = if case .timed(let minutes) = committedMode {
                minutes
            } else {
                0
            }
            let breakTypePayload: BreakTypePayload = switch breakType {
            case .free: .free
            case .committed: .committed(plannedMinutes: plannedMinutes)
            case .safety: .safety
            }
            SnapshotLogging.logBreakStarted(
                petId: petId,
                windPoints: SharedDefaults.monitoredWindPoints,
                breakType: breakTypePayload,
                startDate: now
            )
        }

        WindReminderNotification.cancel { print($0) }

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

        // Award coins for successful committed breaks (persisted for deferred display)
        if success, SharedDefaults.activeBreakType == .committed {
            let coinMinutes: Int
            if let seconds = SharedDefaults.committedBreakMode?.durationSeconds {
                coinMinutes = Int(seconds / 60)
            } else if let startedAt = SharedDefaults.shieldActivatedAt {
                // Open-ended modes (untilZeroWind, untilEndOfDay): use actual elapsed time
                coinMinutes = Int(Date().timeIntervalSince(startedAt) / 60)
            } else {
                coinMinutes = 0
            }
            let coins = CoinRewards.forBreak(minutes: coinMinutes)
            if coins > 0 {
                SharedDefaults.addCoins(coins)
                SharedDefaults.pendingCoinsAwarded += coins
            }
        }

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

    /// Restores break monitoring after app returns to foreground.
    /// Ends expired breaks, processes pending coin rewards, then resumes timer if needed.
    func resumeBreakMonitoringIfNeeded() {
        // End expired breaks first (may persist new pending coins via turnOff)
        if SharedDefaults.isShieldActive, SharedDefaults.activeBreakType != nil {
            checkBreakCompletion()
        }

        // Show reward animation for any pending coins (from background turnOff, midnight reset, or just-completed break)
        processPendingCoins()

        // Resume timer if break is still active
        guard SharedDefaults.isShieldActive else { return }
        startBreakCompletionMonitoring()
    }

    /// Processes pending coin rewards persisted while the app was not visible.
    /// Coins were already added to balance — this triggers the UI reward animation only.
    private func processPendingCoins() {
        let coins = SharedDefaults.pendingCoinsAwarded
        guard coins > 0 else { return }

        ShieldState.shared.setEarnedCoins(coins)
        SharedDefaults.pendingCoinsAwarded = 0

        #if DEBUG
        print("[ShieldManager] Processed pending coins: \(coins)")
        #endif
    }

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
            guard let mode = SharedDefaults.committedBreakMode else { return }
            let isCompleted: Bool
            if let duration = mode.durationSeconds {
                isCompleted = Date().timeIntervalSince(activatedAt) >= duration
            } else if case .untilZeroWind = mode {
                isCompleted = SharedDefaults.effectiveWind <= 0
            } else if case .untilEndOfDay = mode {
                isCompleted = !Calendar.current.isDateInToday(activatedAt)
            } else {
                isCompleted = false
            }
            if isCompleted {
                let shouldAutoLock = SharedDefaults.limitSettings.autoLockAfterCommittedBreak
                let committedEndDate: Date = if let seconds = mode.durationSeconds {
                    activatedAt.addingTimeInterval(seconds)
                } else {
                    Date()
                }
                turnOff(success: true)
                // Show reward immediately only if app is in foreground (timer can briefly fire in background)
                if UIApplication.shared.applicationState == .active {
                    processPendingCoins()
                }
                if shouldAutoLock {
                    // Log the committed → free transition
                    if let petId = SharedDefaults.monitoredPetId {
                        SnapshotStore.shared.appendSync(SnapshotEvent(
                            petId: petId,
                            windPoints: SharedDefaults.monitoredWindPoints,
                            eventType: .breakAutoLocked
                        ))
                    }
                    // Backdate to when the committed break actually ended, not when we detected it
                    turnOn(breakType: .free, committedMode: nil, startDate: committedEndDate)
                }
            }

        case .free:
            if !SharedDefaults.windZeroNotified, SharedDefaults.effectiveWind <= 0 {
                SharedDefaults.windZeroNotified = true
                if SharedDefaults.limitSettings.notifications.shouldSendBreak(.freeBreakWindZero) {
                    BreakNotification.freeBreakWindZero.send()
                }
            }

        case .safety:
            if !SharedDefaults.windZeroNotified, SharedDefaults.effectiveWind <= 0 {
                SharedDefaults.windZeroNotified = true
                if SharedDefaults.limitSettings.notifications.shouldSendBreak(.safetyBreakWindZero) {
                    BreakNotification.safetyBreakWindZero.send()
                }
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

        let oldReduction = SharedDefaults.totalBreakReduction
        let cumulativeSeconds = SharedDefaults.totalCumulativeSeconds

        // Derive secondsForgiven algebraically so that calculatedWind == newWind exactly:
        //   (cumulative - (oldReduction + X)) / limit * 100 = newWind
        //   X = cumulative - oldReduction - newWind * limit / 100
        let exactForgiven = Double(cumulativeSeconds - oldReduction) - newWind * Double(limitSeconds) / 100.0
        let secondsForgiven = max(0, Int(round(exactForgiven)))

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

        let actualMinutes = Int(round(Date().timeIntervalSince(activatedAt) / 60))

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
        processPendingCoins()
    }

    // MARK: - Safety Shield Unlock

    enum SafetyUnlockResult {
        case safe       // wind below high threshold, no penalty
        case blownAway  // wind at or above high threshold, pet lost
    }

    /// Whether the current safety shield can be safely unlocked (wind below configured threshold).
    var isSafetyUnlockSafe: Bool {
        SharedDefaults.effectiveWind < Double(SharedDefaults.limitSettings.safetyUnlockThreshold)
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
        let unlockThreshold = Double(SharedDefaults.limitSettings.safetyUnlockThreshold)
        let result: SafetyUnlockResult = SharedDefaults.monitoredWindPoints < unlockThreshold ? .safe : .blownAway

        logBreakEnded(success: result == .safe)
        deactivateStore()
        SharedDefaults.resetShieldFlags()

        // Restart monitoring to resume wind tracking
        ScreenTimeManager.shared.restartMonitoring()

        ShieldState.shared.refresh()

        return result
    }
}
