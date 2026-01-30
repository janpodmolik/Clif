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

        // Check if this is a new calendar day
        let isNewDay = SharedDefaults.isNewDay
        ExtensionLogger.log("[Extension] isNewDay=\(isNewDay), lastResetDate=\(String(describing: SharedDefaults.lastDayResetDate))")

        if isNewDay {
            // NEW DAY - perform full reset
            ExtensionLogger.log("[Extension] NEW DAY - performing daily reset")

            // Reset wind and activate day start shield
            let didReset = SharedDefaults.performDailyResetIfNeeded()
            ExtensionLogger.log("[Extension] Daily reset performed: \(didReset)")

            // Also activate shield on blocked apps
            if activateShieldFromTokens() {
                ExtensionLogger.log("[Extension] Day start shield activated")
            } else {
                ExtensionLogger.log("[Extension] Failed to load tokens for day start shield")
            }
        } else {
            // Same day - this is monitoring restart (e.g., after app update, reboot)
            // Preserve cumulative baseline so we don't lose tracked time
            let existingThreshold = SharedDefaults.monitoredLastThresholdSeconds

            if existingThreshold > 0 {
                let oldBaseline = SharedDefaults.cumulativeBaseline
                let newBaseline = oldBaseline + existingThreshold
                SharedDefaults.cumulativeBaseline = newBaseline
                SharedDefaults.monitoredLastThresholdSeconds = 0

                ExtensionLogger.log("[Extension] Monitoring restart - baseline updated: \(oldBaseline) + \(existingThreshold) = \(newBaseline)")
            } else {
                ExtensionLogger.log("[Extension] Monitoring restart - no baseline update needed")
            }
        }
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

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        autoreleasepool {
            ExtensionLogger.log("[Extension] eventDidReachThreshold: \(event.rawValue)")

            guard let currentSeconds = parseSecondsFromEvent(event) else { return }

            ExtensionLogger.log("[Extension] current=\(currentSeconds)s")

            SharedDefaults.monitoredLastThresholdSeconds = currentSeconds

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

        if newWindPoints >= 100 {
            checkSafetyShield()
        }

        if let petId = SharedDefaults.monitoredPetId {
            let event = SnapshotEvent(
                petId: petId,
                windPoints: newWindPoints,
                eventType: .usageThreshold(cumulativeSeconds: trueCumulative)
            )
            SnapshotStore.shared.append(event)
            ExtensionLogger.log("[Snapshot] usageThreshold: \(trueCumulative)s")
        }
    }

    // MARK: - Wind Notifications

    private func checkWindNotification(oldWind: Double, newWind: Double) {
        guard let notification = WindNotification.notificationFor(oldWind: oldWind, newWind: newWind) else {
            return
        }

        let settings = SharedDefaults.limitSettings
        guard settings.enabledNotifications.contains(notification) else {
            ExtensionLogger.log("[Notification] Skipped wind_\(notification.percentage)% - disabled in settings")
            return
        }

        notification.send { message in
            ExtensionLogger.log(message)
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
        SharedDefaults.synchronize()

        // Notify the main app so it can refresh ShieldState immediately
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName(DarwinNotifications.safetyShieldActivated as CFString), nil, nil, true)

        ExtensionLogger.log("[SafetyShield] Activated with .safety break type")
    }
}
