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

        logToFile("[Extension] intervalDidStart")

        // Check if this is a new calendar day
        let isNewDay = SharedDefaults.isNewDay
        logToFile("[Extension] isNewDay=\(isNewDay), lastResetDate=\(String(describing: SharedDefaults.lastDayResetDate))")

        if isNewDay {
            // NEW DAY - perform full reset
            logToFile("[Extension] NEW DAY - performing daily reset")

            // Reset wind and activate day start shield
            let didReset = SharedDefaults.performDailyResetIfNeeded()
            logToFile("[Extension] Daily reset performed: \(didReset)")

            // Also activate shield on blocked apps
            activateDayStartShield()

            logToFile("[Extension] Day reset complete - day start shield active")
        } else {
            // Same day - this is monitoring restart (e.g., after app update, reboot)
            // Preserve cumulative baseline so we don't lose tracked time
            let existingThreshold = SharedDefaults.monitoredLastThresholdSeconds

            if existingThreshold > 0 {
                let oldBaseline = SharedDefaults.cumulativeBaseline
                let newBaseline = oldBaseline + existingThreshold
                SharedDefaults.cumulativeBaseline = newBaseline
                SharedDefaults.monitoredLastThresholdSeconds = 0

                logToFile("[Extension] Monitoring restart - baseline updated: \(oldBaseline) + \(existingThreshold) = \(newBaseline)")
            } else {
                logToFile("[Extension] Monitoring restart - no baseline update needed")
            }
        }
    }

    /// Activates shield on all monitored apps for day start flow.
    private func activateDayStartShield() {
        guard let appTokens = SharedDefaults.loadApplicationTokens(),
              let catTokens = SharedDefaults.loadCategoryTokens() else {
            logToFile("[Extension] Failed to load tokens for day start shield")
            return
        }
        let webTokens = SharedDefaults.loadWebDomainTokens() ?? Set()

        if !appTokens.isEmpty {
            store.shield.applications = appTokens
        }
        if !catTokens.isEmpty {
            store.shield.applicationCategories = .specific(catTokens, except: Set())
        }
        if !webTokens.isEmpty {
            store.shield.webDomains = webTokens
        }

        logToFile("[Extension] Day start shield activated on apps")
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        logToFile("[Extension] intervalDidEnd")
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)

        autoreleasepool {
            logToFile("[Extension] eventDidReachThreshold: \(event.rawValue)")

            guard let currentSeconds = parseSecondsFromEvent(event) else { return }

            // Log progress
            let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
            let progressPercent = limitSeconds > 0 ? (Double(currentSeconds) / Double(limitSeconds)) * 100 : 0
            logToFile("[Extension] limitSeconds=\(limitSeconds), current=\(currentSeconds) (\(Int(progressPercent))%)")

            // Skip wind updates if shield is active
            guard shouldProcessThreshold() else {
                // Still update lastThresholdSeconds so we don't get huge delta after unlock
                SharedDefaults.monitoredLastThresholdSeconds = currentSeconds
                return
            }

            // Capture previous threshold for delta calculation
            let previousThresholdSeconds = SharedDefaults.monitoredLastThresholdSeconds

            // Update lastThresholdSeconds
            SharedDefaults.monitoredLastThresholdSeconds = currentSeconds

            processThresholdEvent(currentSeconds: currentSeconds, previousThresholdSeconds: previousThresholdSeconds)
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

        let isShieldActive = SharedDefaults.isShieldActive
        let isDayStartShieldActive = SharedDefaults.isDayStartShieldActive
        logToFile("isShieldActive=\(isShieldActive), isDayStartShieldActive=\(isDayStartShieldActive)")

        if isShieldActive {
            logToFile("Skipping wind - usage shield active")
            return false
        }

        if isDayStartShieldActive {
            logToFile("Skipping wind - day start shield active (preset not selected)")
            return false
        }

        return true
    }

    /// Threshold processing - calculate wind and log.
    /// Uses SharedDefaults.calculateWind for absolute formula: wind = (cumulativeSeconds - breakReduction) / limitSeconds * 100
    private func processThresholdEvent(currentSeconds: Int, previousThresholdSeconds: Int) {
        let oldWindPoints = SharedDefaults.monitoredWindPoints
        let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
        let breakReduction = SharedDefaults.totalBreakReduction
        let baseline = SharedDefaults.cumulativeBaseline

        // Calculate true cumulative: baseline (from before restart) + current threshold
        let trueCumulative = baseline + currentSeconds

        logToFile("========== THRESHOLD ==========")
        logToFile("baseline=\(baseline)s, current=\(currentSeconds)s, trueCumulative=\(trueCumulative)s")
        logToFile("breakReduction=\(breakReduction)s, limit=\(limitSeconds)s")

        // Use SharedDefaults for consistent wind calculation
        let newWindPoints = SharedDefaults.calculateWind(
            cumulativeSeconds: trueCumulative,
            breakReduction: breakReduction,
            limitSeconds: limitSeconds
        )

        // Log BEFORE write
        logToFile("WRITE: wind \(String(format: "%.1f", oldWindPoints)) -> \(String(format: "%.1f", newWindPoints))%")

        SharedDefaults.monitoredWindPoints = newWindPoints

        // Verify write
        let verifyRead = SharedDefaults.monitoredWindPoints
        logToFile("VERIFY: read back = \(String(format: "%.1f", verifyRead))%")

        let effectiveSeconds = max(0, trueCumulative - breakReduction)
        logToFile("effective=\(effectiveSeconds)s")

        // Check for wind notification
        checkWindNotification(oldWind: oldWindPoints, newWind: newWindPoints)

        // Check for safety shield at 100%
        if newWindPoints >= 100 {
            checkSafetyShield()
        }

        // Log snapshot for daily stats
        if let petId = SharedDefaults.monitoredPetId {
            let event = SnapshotEvent(
                petId: petId,
                windPoints: newWindPoints,
                eventType: .usageThreshold(cumulativeSeconds: trueCumulative)
            )
            SnapshotStore.shared.append(event)
            logToFile("[Snapshot] Logged usageThreshold: \(trueCumulative)s")
        }
    }

    // MARK: - Wind Notifications

    /// Checks if a wind notification should be sent based on threshold crossing.
    private func checkWindNotification(oldWind: Double, newWind: Double) {
        guard let notification = WindNotification.notificationFor(oldWind: oldWind, newWind: newWind) else {
            return
        }

        let settings = SharedDefaults.limitSettings
        guard settings.enabledNotifications.contains(notification) else {
            logToFile("[Notification] Skipped wind_\(notification.percentage)% - disabled in settings")
            return
        }

        notification.send { [weak self] message in
            self?.logToFile(message)
        }
    }

    // MARK: - Safety Shield

    /// Activates safety shield when wind reaches 100%.
    /// Sets `.safety` break type to gate blow-away behind explicit user choice.
    private func checkSafetyShield() {
        logToFile("[SafetyShield] Wind >= 100%, checking conditions...")

        // Sync to get fresh data
        SharedDefaults.synchronize()

        // Already active?
        if SharedDefaults.isShieldActive {
            logToFile("[SafetyShield] Shield already active, skipping")
            return
        }

        // Debug disable?
        let settings = SharedDefaults.limitSettings
        if settings.disableSafetyShield {
            logToFile("[SafetyShield] Disabled via debug settings, skipping")
            return
        }

        // Load tokens
        guard let appTokens = SharedDefaults.loadApplicationTokens(),
              let catTokens = SharedDefaults.loadCategoryTokens() else {
            logToFile("[SafetyShield] Failed to load tokens")
            return
        }
        let webTokens = SharedDefaults.loadWebDomainTokens() ?? Set()

        // Activate shield
        if !appTokens.isEmpty {
            store.shield.applications = appTokens
        }
        if !catTokens.isEmpty {
            store.shield.applicationCategories = .specific(catTokens, except: Set())
        }
        if !webTokens.isEmpty {
            store.shield.webDomains = webTokens
        }

        // Set flags — activeBreakType setter syncs isShieldActive automatically
        SharedDefaults.shieldActivatedAt = Date()
        SharedDefaults.activeBreakType = .safety
        SharedDefaults.synchronize()

        logToFile("[SafetyShield] Shield activated at 100% with .safety break type")
    }

    private func logToFile(_ message: String) {
        ExtensionLogger.log(message)
    }
}
