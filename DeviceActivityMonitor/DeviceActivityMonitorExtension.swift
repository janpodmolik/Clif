import DeviceActivity
import Foundation
import ManagedSettings

/// Background extension that monitors device activity and updates wind.
/// Runs in a separate process with limited memory (~6MB).
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()

    // MARK: - DeviceActivityMonitor Overrides

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        ExtensionLogger.log("[Extension] intervalDidStart")
        saveBaselineAndResetThreshold()
        // PHANTOM_BURST_WORKAROUND — anchor for the absolute validator: any event
        // whose `current` seconds exceeds wall-clock since this moment is phantom.
        // Also clear lastThresholdTimestamp so the inter-event check restarts cleanly.
        SharedDefaults.currentIntervalStartedAt = Date()
        SharedDefaults.lastThresholdTimestamp = nil
        activateDayStartShieldIfNeeded()
    }

    /// Activates Day Start Shield reactively when a new day is detected.
    /// Called from intervalDidStart (midnight) and eventDidReachThreshold (first usage).
    private func activateDayStartShieldIfNeeded() {
        SharedDefaults.synchronize()

        guard SharedDefaults.isNewDay,
              !SharedDefaults.isShieldActive,
              !SharedDefaults.isDayStartShieldActive else {
            return
        }

        let settings = SharedDefaults.limitSettings
        if settings.dayStartShieldEnabled {
            let activated = activateShieldFromTokens()
            if activated {
                SharedDefaults.isDayStartShieldActive = true
                SharedDefaults.synchronize()
                ExtensionLogger.log("[Extension] New day - preset shield activated")
            } else {
                ExtensionLogger.log("[Extension] New day - FAILED to activate shield (no tokens)")
            }
        } else {
            ExtensionLogger.log("[Extension] New day - auto-apply mode, skipping shield")
        }
    }

    // MARK: - Baseline Accounting

    /// Saves current threshold into cumulative baseline and resets threshold counter.
    /// Called on interval boundaries (start/end) to preserve tracked time across monitoring restarts.
    private func saveBaselineAndResetThreshold() {
        let existingThreshold = SharedDefaults.monitoredLastThresholdSeconds
        guard existingThreshold > 0 else {
            ExtensionLogger.log("[Extension] Baseline - no update needed")
            return
        }

        let oldBaseline = SharedDefaults.cumulativeBaseline
        let newBaseline = oldBaseline + existingThreshold
        SharedDefaults.cumulativeBaseline = newBaseline
        SharedDefaults.monitoredLastThresholdSeconds = 0

        ExtensionLogger.log("[Extension] Baseline updated: \(oldBaseline) + \(existingThreshold) = \(newBaseline)")
    }

    /// Loads stored tokens and applies them to ManagedSettingsStore.
    /// Returns false if no tokens could be loaded.
    @discardableResult
    private func activateShieldFromTokens() -> Bool {
        let appTokens = SharedDefaults.loadApplicationTokens() ?? Set()
        let catTokens = SharedDefaults.loadCategoryTokens() ?? Set()
        let webTokens = SharedDefaults.loadWebDomainTokens() ?? Set()

        guard !appTokens.isEmpty || !catTokens.isEmpty || !webTokens.isEmpty else {
            return false
        }

        if !appTokens.isEmpty {
            store.shield.applications = appTokens
        }
        if !catTokens.isEmpty {
            store.shield.applicationCategories = .specific(catTokens, except: Set())
        }
        if !webTokens.isEmpty {
            store.shield.webDomains = webTokens
        }
        return true
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        ExtensionLogger.log("[Extension] intervalDidEnd")
        saveBaselineAndResetThreshold()
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        autoreleasepool {
            // Sentinel threshold — only activates Day Start Shield, no wind processing
            if event.rawValue == EventNames.dayStartSentinel {
                activateDayStartShieldIfNeeded()
                return
            }

            guard let currentSeconds = parseSecondsFromEvent(event) else {
                ExtensionLogger.log("[Extension] eventDidReachThreshold: unparseable event=\(event.rawValue)")
                return
            }

            let petId = SharedDefaults.monitoredPetId?.uuidString ?? "nil"
            let limit = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
            let baseline = SharedDefaults.cumulativeBaseline
            let lastProcessed = SharedDefaults.monitoredLastThresholdSeconds
            let wallDelta: String = {
                guard let last = SharedDefaults.lastThresholdTimestamp else { return "nil" }
                return String(format: "%.2fs", Date().timeIntervalSince(last))
            }()
            ExtensionLogger.log("[Extension] eventDidReachThreshold: event=\(event.rawValue) current=\(currentSeconds)s last=\(lastProcessed)s delta=\(currentSeconds - lastProcessed)s wallDelta=\(wallDelta) petId=\(petId) limit=\(limit)s baseline=\(baseline)s")

            // Guard against out-of-order threshold bursts: only process if this threshold
            // is higher than the last one we processed. When monitoring restarts, iOS may fire
            // multiple thresholds simultaneously in non-deterministic order.
            guard currentSeconds > lastProcessed else {
                ExtensionLogger.log("[Extension] Skipping out-of-order threshold: \(currentSeconds)s <= last \(lastProcessed)s wallDelta=\(wallDelta)")
                return
            }

            // iOS 26.2 phantom burst guard — see validateThresholdAgainstWallClock header.
            // nil return = phantom event, drop it entirely (don't even move the cursor).
            // Over-limit safety-net events bypass the drop and clamp instead, so the safety shield
            // can never be stranded by a dropped 100% event.
            guard let adjustedSeconds = validateThresholdAgainstWallClock(
                currentSeconds: currentSeconds,
                lastProcessedSeconds: lastProcessed,
                isOverLimit: isOverLimitEvent(event)
            ) else {
                return
            }

            SharedDefaults.monitoredLastThresholdSeconds = adjustedSeconds
            SharedDefaults.lastThresholdTimestamp = Date()

            activateDayStartShieldIfNeeded()

            guard shouldProcessThreshold() else { return }

            processThresholdEvent(currentSeconds: adjustedSeconds)
        }
    }

    // MARK: - Threshold Processing

    private func parseSecondsFromEvent(_ event: DeviceActivityEvent.Name) -> Int? {
        let eventName = event.rawValue
        // Both `second_<n>` (sub-limit) and `overlimit_<n>` (PHANTOM_BURST_WORKAROUND safety net)
        // encode their threshold seconds as the last `_`-separated component.
        guard eventName.hasPrefix(EventNames.secondPrefix) || eventName.hasPrefix(EventNames.overLimitPrefix),
              let valueString = eventName.split(separator: "_").last,
              let seconds = Int(valueString) else {
            return nil
        }
        return seconds
    }

    /// PHANTOM_BURST_WORKAROUND — true for the over-limit safety-net threshold.
    /// These events bypass the phantom-burst drop (clamp-only) so a single dropped 100% event
    /// can never strand the user just below the safety shield activation threshold.
    private func isOverLimitEvent(_ event: DeviceActivityEvent.Name) -> Bool {
        event.rawValue.hasPrefix(EventNames.overLimitPrefix)
    }

    // MARK: - PHANTOM_BURST_WORKAROUND (iOS 26.2 — FB21450954)
    // -------------------------------------------------------------------------
    // Workaround for confirmed Apple bug: DeviceActivityMonitor.eventDidReachThreshold
    // fires phantom events on iOS 26.2 without corresponding real app usage —
    // sometimes dozens in a single millisecond, causing wind jumps of 50+ percentage
    // points. Related radars: FB18351583, FB13696022, FB21320644.
    //
    // Apple Developer Relations acknowledged the bug but hasn't shipped a fix.
    // Community reports point at iOS 26.5 as the likely fix target
    // (see AppConstants.phantomBurstAssumedFixedVersion).
    //
    // Tracking: https://developer.apple.com/forums/thread/811305
    //
    // When removing: grep the repo for `PHANTOM_BURST_WORKAROUND` to find every site.
    //   1) this file — validateThresholdAgainstWallClock + the caller guard +
    //      isOverLimitEvent + parseSecondsFromEvent's overLimitPrefix branch
    //   2) SharedDefaults+Wind.swift — burstDrop accessors + registerBurstDrop
    //   3) Constants.swift — burstDrop keys + phantomBurstAssumedFixedVersion +
    //      overLimitThresholdNumerator/Denominator + EventNames.overLimitPrefix
    //      + drop reservedThresholds back to 1
    //   4) ScreenTimeManager.swift — over-limit threshold emission in MonitoringEventBuilder
    //   5) TroubleshootingScreen.swift + ProfileDestination.troubleshooting
    //   6) MainApp.swift — checkPhantomBurstWorkaroundRelevance()
    // -------------------------------------------------------------------------

    /// Detects phantom threshold bursts by the physical-limit principle:
    /// reported usage cannot accumulate faster than wall-clock time passes.
    ///
    /// Returns the seconds value to store for this event, or `nil` if the event is a phantom
    /// burst and should be ignored entirely (nothing written, wind unchanged).
    ///
    /// Two-layer defence:
    /// 1. **Absolute check** (interval-bound) — `current` seconds cannot exceed how long
    ///    the current DeviceActivity interval has been running. This catches iOS flushing
    ///    queued events from a previous interval after monitoring restart — the canonical
    ///    phantom burst symptom.
    /// 2. **Inter-event check** (delta-bound) — the per-event increase cannot exceed
    ///    wall-clock elapsed since the previous processed event. Catches mid-interval
    ///    bursts where multiple events arrive in the same millisecond.
    ///
    /// Grace of 10s absorbs iOS's normal delivery jitter.
    ///
    /// **Over-limit clamp mode** (`isOverLimit == true`): for the safety-net threshold past 100%
    /// of the limit, dropping is unsafe — it would let the user keep using limited apps with wind
    /// frozen near 100% and the safety shield never activating. In this mode the guard never
    /// returns nil; if a check would have failed it clamps `currentSeconds` to the largest plausible
    /// value (`lastProcessed + plausibleIncrease`) and lets the event through. Worst-case loss is
    /// some accuracy on the 110% number — much better than losing the safety shield trigger.
    private func validateThresholdAgainstWallClock(
        currentSeconds: Int,
        lastProcessedSeconds: Int,
        isOverLimit: Bool
    ) -> Int? {
        let graceSeconds = 10
        let now = Date()

        // Absolute check — bounds `current` against the current interval's age.
        if let intervalStart = SharedDefaults.currentIntervalStartedAt {
            let intervalAge = now.timeIntervalSince(intervalStart)
            let plausibleMax = Int(ceil(intervalAge)) + graceSeconds
            if currentSeconds > plausibleMax {
                let dropped = currentSeconds - lastProcessedSeconds
                SharedDefaults.registerBurstDrop(droppedSeconds: dropped)
                if isOverLimit {
                    // Clamp must advance the cursor past `lastProcessedSeconds` — otherwise
                    // when the absolute check fires right after a monitoring restart (small
                    // intervalAge, plausibleMax ~ 11s) the cursor wouldn't move and the wind
                    // would never cross the safety-shield threshold. `lastProcessed + plausibleMax`
                    // mirrors the inter-event branch below: advance by a wall-clock-bounded delta.
                    let clamped = lastProcessedSeconds + plausibleMax
                    ExtensionLogger.log("[Extension] PHANTOM BURST clamped (over-limit): current=\(currentSeconds)s → \(clamped)s (interval \(String(format: "%.2f", intervalAge))s old)")
                    return clamped
                }
                ExtensionLogger.log("[Extension] PHANTOM BURST ignored: current=\(currentSeconds)s but interval only \(String(format: "%.2f", intervalAge))s old (allowed=\(plausibleMax)s) — event discarded")
                return nil
            }
        }

        // Inter-event check — bounds the per-event delta against wall-clock between events.
        guard let lastTimestamp = SharedDefaults.lastThresholdTimestamp else {
            // First event in this interval — no delta to check, absolute check already passed.
            ExtensionLogger.log("[Extension] validate: first threshold in interval → pass current=\(currentSeconds)s")
            return currentSeconds
        }

        let wallClockElapsed = now.timeIntervalSince(lastTimestamp)
        let reportedIncrease = currentSeconds - lastProcessedSeconds
        guard reportedIncrease > 0 else { return currentSeconds }

        let plausibleIncrease = Int(ceil(wallClockElapsed)) + graceSeconds
        if reportedIncrease > plausibleIncrease {
            SharedDefaults.registerBurstDrop(droppedSeconds: reportedIncrease)
            if isOverLimit {
                let clamped = lastProcessedSeconds + plausibleIncrease
                ExtensionLogger.log("[Extension] PHANTOM BURST clamped (over-limit): reported=+\(reportedIncrease)s in \(String(format: "%.2f", wallClockElapsed))s → current \(currentSeconds)s clamped to \(clamped)s")
                return clamped
            }
            ExtensionLogger.log("[Extension] PHANTOM BURST ignored: reported=+\(reportedIncrease)s in \(String(format: "%.2f", wallClockElapsed))s (allowed=\(plausibleIncrease)s) — event discarded")
            return nil
        }

        ExtensionLogger.log("[Extension] validate: OK reported=+\(reportedIncrease)s in \(String(format: "%.2f", wallClockElapsed))s → pass current=\(currentSeconds)s")
        return currentSeconds
    }

    private func shouldProcessThreshold() -> Bool {
        SharedDefaults.synchronize()

        if SharedDefaults.isShieldActive {
            ExtensionLogger.log("Skipping wind - usage shield active")
            return false
        }
        if SharedDefaults.isDayStartShieldActive {
            ExtensionLogger.log("Skipping wind - day start shield active")
            return false
        }
        return true
    }

    private func processThresholdEvent(currentSeconds: Int) {
        let oldWindPoints = SharedDefaults.monitoredWindPoints
        let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
        let breakReduction = SharedDefaults.totalBreakReduction
        let baseline = SharedDefaults.cumulativeBaseline
        let trueCumulative = baseline + currentSeconds

        ExtensionLogger.log("THRESHOLD: cumulative=\(trueCumulative)s (baseline=\(baseline)+current=\(currentSeconds)), break=\(breakReduction)s, limit=\(limitSeconds)s")

        let newWindPoints = SharedDefaults.calculateWind(
            cumulativeSeconds: trueCumulative,
            breakReduction: breakReduction,
            limitSeconds: limitSeconds
        )

        ExtensionLogger.log("Wind: \(String(format: "%.1f", oldWindPoints)) -> \(String(format: "%.1f", newWindPoints))%")

        SharedDefaults.monitoredWindPoints = newWindPoints

        checkWindNotification(oldWind: oldWindPoints, newWind: newWindPoints)
        checkWindReminder(newWind: newWindPoints)

        let safetyThreshold = Double(SharedDefaults.limitSettings.safetyShieldActivationThreshold)
        if newWindPoints >= safetyThreshold {
            checkSafetyShield()
        }

        if let petId = SharedDefaults.monitoredPetId {
            let event = SnapshotEvent(
                petId: petId,
                windPoints: newWindPoints,
                eventType: .usageThreshold(cumulativeSeconds: trueCumulative)
            )
            SnapshotStore.shared.append(event)
        }
    }

    // MARK: - Wind Notifications

    private func checkWindNotification(oldWind: Double, newWind: Double) {
        guard let notification = WindNotification.notificationFor(oldWind: oldWind, newWind: newWind) else {
            return
        }

        let settings = SharedDefaults.limitSettings
        guard settings.notifications.shouldSendWind(notification) else {
            ExtensionLogger.log("[Notification] Skipped wind_\(notification.percentage)% - disabled in settings")
            return
        }

        notification.send { message in
            ExtensionLogger.log(message)
        }
    }

    // MARK: - Wind Reminder

    /// Schedules or cancels the wind reminder notification based on current wind level.
    /// When wind is active (>0%), schedules a reminder 5 min from now (resets on each threshold event).
    /// At zero wind, cancels any pending reminder.
    private func checkWindReminder(newWind: Double) {
        let settings = SharedDefaults.limitSettings
        guard settings.notifications.shouldSendWindReminder() else { return }

        if newWind > 0 {
            guard !SharedDefaults.windReminderSent else { return }
            SharedDefaults.windReminderSent = true
            WindReminderNotification.schedule { message in
                ExtensionLogger.log(message)
            }
        } else {
            SharedDefaults.windReminderSent = false
            WindReminderNotification.cancel { message in
                ExtensionLogger.log(message)
            }
        }
    }

    // MARK: - Safety Shield

    private func checkSafetyShield() {
        SharedDefaults.synchronize()

        if SharedDefaults.isShieldActive {
            ExtensionLogger.log("[SafetyShield] Shield already active, skipping")
            return
        }
        if SharedDefaults.limitSettings.disableSafetyShield {
            ExtensionLogger.log("[SafetyShield] Disabled via debug settings, skipping")
            return
        }

        guard activateShieldFromTokens() else {
            ExtensionLogger.log("[SafetyShield] Failed to load tokens")
            return
        }

        SharedDefaults.shieldActivatedAt = Date()
        SharedDefaults.activeBreakType = .safety
        SharedDefaults.isDayStartShieldActive = false
        SharedDefaults.synchronize()

        // Notify the main app so it can refresh ShieldState immediately
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName(DarwinNotifications.safetyShieldActivated as CFString), nil, nil, true)

        WindReminderNotification.cancel { message in
            ExtensionLogger.log(message)
        }

        ExtensionLogger.log("[SafetyShield] Activated with .safety break type")
    }
}
