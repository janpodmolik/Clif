import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import UserNotifications

/// Background extension that monitors device activity and updates progress.
/// Runs in a separate process with very limited memory (~6MB).
/// Keep this as lightweight as possible!
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()

    // MARK: - DeviceActivityMonitor Overrides

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        // Check if this is actually a new day or just a monitoring restart (e.g., after rebuild)
        // If we already have wind points for today, skip the reset
        let existingWindPoints = SharedDefaults.monitoredWindPoints
        let existingThreshold = SharedDefaults.monitoredLastThresholdSeconds

        if existingWindPoints > 0 || existingThreshold > 0 {
            logToFile("[Extension] intervalDidStart skipped reset - existing wind: \(existingWindPoints), threshold: \(existingThreshold)")
            return
        }

        // Reset wind state for new day
        SharedDefaults.currentProgress = 0
        SharedDefaults.monitoredWindPoints = 0
        SharedDefaults.monitoredLastThresholdSeconds = 0
        SharedDefaults.lastKnownWindLevel = WindLevel.none.rawValue

        // Reset preset lock for new day
        SharedDefaults.windPresetLockedForToday = false
        SharedDefaults.windPresetLockedDate = nil

        // Reset blow away and safety notification state for new day
        SharedDefaults.set(false, forKey: DefaultsKeys.petBlownAway)
        SharedDefaults.set(false, forKey: DefaultsKeys.safetyShieldNotificationSent)

        let settings = SharedDefaults.limitSettings

        if settings.morningShieldEnabled {
            // Activate Morning Shield
            SharedDefaults.isMorningShieldActive = true
            activateShield()
            logToFile("[Extension] Morning Shield activated")
        } else {
            // Clear shields at start of new day
            SharedDefaults.isMorningShieldActive = false
            SharedDefaults.isShieldActive = false
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            store.shield.webDomains = nil
        }

        // Log systemDayStart snapshot
        logSnapshot(eventType: .systemDayStart)
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)

        // Log systemDayEnd snapshot
        logSnapshot(eventType: .systemDayEnd)
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
        let isMorningShieldActive = SharedDefaults.isMorningShieldActive

        logToFile("DEBUG: isShieldActive=\(isShieldActive), isMorningShieldActive=\(isMorningShieldActive)")

        if isShieldActive {
            logToFile("DEBUG: Skipping wind - shield is active")
            return false
        }

        if isMorningShieldActive {
            logToFile("DEBUG: Skipping wind - morning shield is active")
            return false
        }

        return true
    }

    /// Full threshold processing - wind update, level changes, safety shield, snapshots.
    private func processThresholdEvent(currentSeconds: Int, previousThresholdSeconds: Int) {
        // Calculate wind delta from previous threshold
        let deltaSeconds = currentSeconds - previousThresholdSeconds
        let riseRate = SharedDefaults.monitoredRiseRate
        let oldWindPoints = SharedDefaults.monitoredWindPoints

        logToFile("========== THRESHOLD EVENT ==========")
        logToFile("Seconds: current=\(currentSeconds), previous=\(previousThresholdSeconds), delta=\(deltaSeconds)")

        // After unlock + monitoring restart, thresholds start from 0 again
        // but previousThresholdSeconds might be higher (from before unlock).
        // In this case delta is negative/zero - skip wind update but still log snapshot.
        guard deltaSeconds > 0 else {
            logToFile("Skipping wind update - delta <= 0 (monitoring was restarted)")
            logSnapshot(eventType: .usageThreshold(cumulativeSeconds: currentSeconds))
            return
        }

        // Update wind points
        let newWindPoints = updateWindPoints(oldWindPoints: oldWindPoints, deltaSeconds: deltaSeconds, riseRate: riseRate)
        SharedDefaults.monitoredWindPoints = newWindPoints

        logToFile("riseRate=\(riseRate), Wind: \(oldWindPoints) -> \(newWindPoints)")

        checkWindLevelChange(windPoints: newWindPoints)
        checkSafetyShield(windPoints: newWindPoints)
        logSnapshot(eventType: .usageThreshold(cumulativeSeconds: currentSeconds))
    }

    private func updateWindPoints(oldWindPoints: Double, deltaSeconds: Int, riseRate: Double) -> Double {
        let windIncrease = Double(deltaSeconds) * riseRate
        return min(oldWindPoints + windIncrease, 100)
    }

    private func checkWindLevelChange(windPoints: Double) {
        let newLevel = WindLevel.from(windPoints: windPoints)
        let lastKnownLevel = WindLevel(rawValue: SharedDefaults.lastKnownWindLevel) ?? .none

        logToFile("WindLevel: current=\(newLevel), last=\(lastKnownLevel)")

        guard newLevel != lastKnownLevel else { return }

        SharedDefaults.lastKnownWindLevel = newLevel.rawValue
        logToFile("WindLevel CHANGED: \(lastKnownLevel) -> \(newLevel)")

        let settings = SharedDefaults.limitSettings

        // Activate shield when we CROSS the activation threshold for the first time
        // Only activate if: previous level was below threshold AND new level is at/above threshold
        // Note: Safety shield at 100% is handled separately in checkSafetyShield()
        if let activationLevel = settings.shieldActivationLevel,
           lastKnownLevel.rawValue < activationLevel.rawValue,
           newLevel.rawValue >= activationLevel.rawValue {
            logToFile(">>> ACTIVATING SHIELD - crossed threshold at level \(newLevel)")
            activateShield()
        }

        // Send notification if enabled for this level
        if settings.notificationLevels.contains(newLevel) {
            logToFile(">>> SENDING NOTIFICATION for level \(newLevel)")
            sendWindLevelNotification(level: newLevel)
        }
    }

    /// Checks if 100% safety shield should activate and sends warning notification.
    /// This is a system safeguard that ALWAYS activates at 100%, regardless of user settings.
    /// Can be disabled via LimitSettings.disableSafetyShield for debug purposes.
    private func checkSafetyShield(windPoints: Double) {
        // Safety shield activates at exactly 100 wind points (not in buffer zone yet)
        guard windPoints >= 100 else { return }

        // Check debug override
        let settings = SharedDefaults.limitSettings
        if settings.disableSafetyShield {
            logToFile("[SafetyShield] DISABLED via debug settings, skipping")
            return
        }

        // Always send the critical warning notification at 100%
        // This warns user even if shield was already activated at lower threshold
        let alreadySent = SharedDefaults.bool(forKey: DefaultsKeys.safetyShieldNotificationSent)
        if !alreadySent {
            logToFile(">>> SENDING 100% WARNING NOTIFICATION")
            sendSafetyShieldNotification()
            SharedDefaults.set(true, forKey: DefaultsKeys.safetyShieldNotificationSent)
        }

        // Activate shield if not already active
        let isAlreadyActive = SharedDefaults.isShieldActive
        if !isAlreadyActive {
            logToFile(">>> SAFETY SHIELD ACTIVATED at 100%")
            activateShield()
        } else {
            logToFile("[SafetyShield] Shield already active, skipping activation")
        }
    }

    private func sendSafetyShieldNotification() {
        sendNotification(
            title: "Kritický stav!",
            body: "Jakékoliv další používání velmi pravděpodobně odfoukne tvého mazlíčka.",
            identifier: "safetyShield",
            deepLink: DeepLinks.home
        )
    }

    private func sendBlowAwayNotification() {
        BlowAwayNotification.send { [weak self] message in
            self?.logToFile(message)
        }
    }

    private func logToFile(_ message: String) {
        ExtensionLogger.log(message)
    }

    // MARK: - Snapshot Logging

    private func logSnapshot(eventType: SnapshotEventType) {
        autoreleasepool {
            guard let petId = SharedDefaults.monitoredPetId else {
                return
            }

            let windPoints = SharedDefaults.monitoredWindPoints

            let event = SnapshotEvent(
                petId: petId,
                windPoints: windPoints,
                eventType: eventType
            )

            SnapshotStore.shared.appendSync(event)
        }
    }

    // MARK: - Helpers

    /// Activates shield for selected apps/categories
    private func activateShield() {
        // Use autoreleasepool to minimize memory footprint
        autoreleasepool {
            logToFile("[activateShield] START")

            // Use lightweight token loading instead of full FamilyActivitySelection decode
            let appTokens = SharedDefaults.loadApplicationTokens()
            let catTokens = SharedDefaults.loadCategoryTokens()
            let webTokens = SharedDefaults.loadWebDomainTokens()

            logToFile("[activateShield] Loaded tokens - apps: \(appTokens?.count ?? -1), cats: \(catTokens?.count ?? -1), webs: \(webTokens?.count ?? -1)")

            var shieldApplied = false

            if let appTokens = appTokens, !appTokens.isEmpty {
                store.shield.applications = appTokens
                shieldApplied = true
                logToFile("[activateShield] Applied \(appTokens.count) app tokens")
            } else {
                logToFile("[activateShield] WARNING: No app tokens to apply!")
            }

            if let catTokens = catTokens, !catTokens.isEmpty {
                store.shield.applicationCategories = .specific(catTokens, except: Set())
                shieldApplied = true
                logToFile("[activateShield] Applied \(catTokens.count) category tokens")
            } else {
                logToFile("[activateShield] WARNING: No category tokens to apply!")
            }

            if let webTokens = webTokens, !webTokens.isEmpty {
                store.shield.webDomains = webTokens
                shieldApplied = true
                logToFile("[activateShield] Applied \(webTokens.count) web tokens")
            }

            if !shieldApplied {
                logToFile("[activateShield] ERROR: No tokens applied! Shield will not work!")
            }

            // Mark shield as active - wind should not increase while shield is shown
            // Save activation timestamp for wind decrease calculation
            SharedDefaults.isShieldActive = true
            SharedDefaults.shieldActivatedAt = Date()
            SharedDefaults.synchronize()
            logToFile("[activateShield] END - isShieldActive = true, shieldActivatedAt = \(Date()), shieldApplied = \(shieldApplied)")
        }
    }

    /// Sends notification when wind level changes
    private func sendWindLevelNotification(level: WindLevel) {
        let (title, body): (String, String)

        switch level {
        case .none:
            return
        case .low:
            (title, body) = ("Vítr se zvedá", "Tvůj mazlíček cítí mírný vánek. Možná čas na přestávku?")
        case .medium:
            (title, body) = ("Silnější vítr!", "Tvůj mazlíček se drží. Zvažuj zpomalení.")
        case .high:
            (title, body) = ("Nebezpečný vítr!", "Tvůj mazlíček je v ohrožení! Zastav se než bude pozdě.")
        }

        sendNotification(
            title: title,
            body: body,
            identifier: "windLevel_\(level.rawValue)",
            deepLink: DeepLinks.home
        )
    }

    private func sendNotification(title: String, body: String, identifier: String, deepLink: String) {
        logToFile("[Notification] Sending: \(identifier) - \(title)")

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["deepLink": deepLink]
        content.interruptionLevel = .timeSensitive

        let requestId = "\(identifier)_\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: requestId,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logToFile("[Notification] FAILED: \(identifier) - \(error.localizedDescription)")
            } else {
                self?.logToFile("[Notification] SUCCESS: \(identifier)")
            }
        }
    }
}
