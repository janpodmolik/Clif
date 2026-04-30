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
            ExtensionLogger.log("[Extension] eventDidReachThreshold: event=\(event.rawValue) current=\(currentSeconds)s last=\(lastProcessed)s delta=\(currentSeconds - lastProcessed)s petId=\(petId) limit=\(limit)s baseline=\(baseline)s")

            // Skip out-of-order events: when monitoring restarts iOS can flush queued
            // thresholds in non-deterministic order, including ones we've already passed.
            guard currentSeconds > lastProcessed else {
                ExtensionLogger.log("[Extension] Skipping out-of-order threshold: \(currentSeconds)s <= last \(lastProcessed)s")
                return
            }

            SharedDefaults.monitoredLastThresholdSeconds = currentSeconds

            activateDayStartShieldIfNeeded()

            guard shouldProcessThreshold() else { return }

            processThresholdEvent(currentSeconds: currentSeconds)
        }
    }

    // MARK: - Threshold Processing

    private func parseSecondsFromEvent(_ event: DeviceActivityEvent.Name) -> Int? {
        let eventName = event.rawValue
        guard eventName.hasPrefix(EventNames.secondPrefix),
              let valueString = eventName.split(separator: "_").last,
              let seconds = Int(valueString) else {
            return nil
        }
        return seconds
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
    /// When wind is at or above `WindReminderNotification.triggerThreshold`, schedules a reminder
    /// 5 min from now (resets on each threshold event). Below the threshold, cancels any pending
    /// reminder.
    private func checkWindReminder(newWind: Double) {
        let settings = SharedDefaults.limitSettings
        guard settings.notifications.shouldSendWindReminder() else { return }

        if newWind >= WindReminderNotification.triggerThreshold {
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
