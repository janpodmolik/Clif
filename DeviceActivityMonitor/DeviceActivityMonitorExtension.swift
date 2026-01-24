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

        // Reset wind state for new day
        SharedDefaults.currentProgress = 0
        SharedDefaults.monitoredWindPoints = 0
        SharedDefaults.monitoredLastThresholdSeconds = 0
        SharedDefaults.lastKnownWindLevel = WindLevel.none.rawValue

        // Reset preset lock for new day
        SharedDefaults.windPresetLockedForToday = false
        SharedDefaults.windPresetLockedDate = nil

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

    private func processThresholdEvent(currentSeconds: Int) {
        let lastSeconds = SharedDefaults.monitoredLastThresholdSeconds
        let rawRiseRate = SharedDefaults.monitoredRiseRate
        let riseRatePerSecond = rawRiseRate > 0 ? rawRiseRate : (100.0 / 60.0)
        let oldWindPoints = SharedDefaults.monitoredWindPoints
        let deltaSeconds = currentSeconds - lastSeconds

        logToFile("========== THRESHOLD EVENT ==========")
        logToFile("Seconds: current=\(currentSeconds), last=\(lastSeconds), delta=\(deltaSeconds)")
        logToFile("Wind: old=\(oldWindPoints), riseRate=\(riseRatePerSecond)/s")

        if deltaSeconds > 0 {
            let newWindPoints = updateWindPoints(
                oldWindPoints: oldWindPoints,
                deltaSeconds: deltaSeconds,
                riseRate: riseRatePerSecond
            )

            SharedDefaults.monitoredWindPoints = newWindPoints
            SharedDefaults.monitoredLastThresholdSeconds = currentSeconds
            SharedDefaults.synchronize()

            logToFile("Wind UPDATE: \(oldWindPoints) + \(Double(deltaSeconds) * riseRatePerSecond) = \(newWindPoints)")

            checkWindLevelChange(windPoints: newWindPoints)
        } else {
            logToFile("Skipping wind update: deltaSeconds=\(deltaSeconds) <= 0")
        }

        logSnapshot(eventType: .usageThreshold(cumulativeSeconds: currentSeconds))
        checkLimitReached(currentSeconds: currentSeconds)
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

        // Activate shield if threshold reached (but not at 100% - pet already blown)
        if let activationLevel = settings.shieldActivationLevel,
           newLevel.rawValue >= activationLevel.rawValue,
           windPoints < 100 {
            logToFile(">>> ACTIVATING SHIELD at level \(newLevel)")
            activateShield()
        }

        // Send notification if enabled for this level
        if settings.notificationLevels.contains(newLevel) {
            logToFile(">>> SENDING NOTIFICATION for level \(newLevel)")
            sendWindLevelNotification(level: newLevel)
        }
    }

    private func checkLimitReached(currentSeconds: Int) {
        let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
        logToFile("[Extension] limitSeconds=\(limitSeconds), checking if \(currentSeconds) >= \(limitSeconds)")

        if currentSeconds >= limitSeconds {
            logToFile("[Extension] LIMIT REACHED (100%) - pet blown away")
            sendLimitReachedNotification()
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
            SharedDefaults.isShieldActive = true
            SharedDefaults.synchronize()
            logToFile("[activateShield] END - isShieldActive = true, shieldApplied = \(shieldApplied)")
        }
    }

    /// Sends notification when screen time limit is reached
    private func sendLimitReachedNotification() {
        sendNotification(
            title: "Screen Time Limit Reached",
            body: "Your pet is being blown away by the wind!",
            identifier: "limitReached",
            deepLink: DeepLinks.shield
        )
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
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = ["deepLink": deepLink]
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "\(identifier)_\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logToFile("[Extension] Failed to send notification: \(error.localizedDescription)")
            }
        }
    }
}
