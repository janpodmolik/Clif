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

        // Use autoreleasepool to immediately free memory in this memory-constrained extension
        autoreleasepool {
            let eventName = event.rawValue

            // Force read latest values from disk (cross-process sync)
            SharedDefaults.synchronize()

            let isShieldActive = SharedDefaults.isShieldActive
            let isMorningShieldActive = SharedDefaults.isMorningShieldActive
            logToFile("[Extension] eventDidReachThreshold: \(eventName)")
            logToFile("DEBUG: isShieldActive=\(isShieldActive), isMorningShieldActive=\(isMorningShieldActive)")

            // Don't increase wind while shield is active - user can't actually use the app
            if isShieldActive {
                logToFile("DEBUG: Skipping wind - shield is active")
                return
            }

            // Don't process wind during morning shield - user hasn't selected preset yet
            if isMorningShieldActive {
                logToFile("DEBUG: Skipping wind - morning shield is active")
                return
            }

            // Parse seconds from event name "second_X"
            if eventName.hasPrefix("second_"),
               let valueString = eventName.split(separator: "_").last,
               let currentSeconds = Int(valueString) {

                // Calculate wind increase directly in extension
                let lastSeconds = SharedDefaults.monitoredLastThresholdSeconds
                let rawRiseRate = SharedDefaults.monitoredRiseRate
                // Validate riseRate: must be positive, fallback to default (100pts/60sec = ~1.67 pts/sec)
                let riseRatePerSecond = rawRiseRate > 0 ? rawRiseRate : (100.0 / 60.0)
                let oldWindPoints = SharedDefaults.monitoredWindPoints
                let deltaSeconds = currentSeconds - lastSeconds

                logToFile("========== THRESHOLD EVENT ==========")
                logToFile("Event: \(eventName)")
                logToFile("Seconds: current=\(currentSeconds), last=\(lastSeconds), delta=\(deltaSeconds)")
                logToFile("Wind: old=\(oldWindPoints), riseRate=\(riseRatePerSecond)/s")
                logToFile("Flags: isShieldActive=\(isShieldActive), isMorningShieldActive=\(isMorningShieldActive)")

                if deltaSeconds > 0 {
                    var windPoints = oldWindPoints
                    let windIncrease = Double(deltaSeconds) * riseRatePerSecond
                    windPoints += windIncrease
                    windPoints = min(windPoints, 100)

                    // Update SharedDefaults so main app can read it
                    SharedDefaults.monitoredWindPoints = windPoints
                    SharedDefaults.monitoredLastThresholdSeconds = currentSeconds
                    SharedDefaults.synchronize()

                    logToFile("Wind UPDATE: \(oldWindPoints) + \(windIncrease) = \(windPoints)")

                    // Check for WindLevel change
                    let newLevel = WindLevel.from(windPoints: windPoints)
                    let lastKnownLevel = WindLevel(rawValue: SharedDefaults.lastKnownWindLevel) ?? .none

                    logToFile("WindLevel: current=\(newLevel) (raw=\(newLevel.rawValue)), last=\(lastKnownLevel) (raw=\(lastKnownLevel.rawValue))")

                    if newLevel != lastKnownLevel {
                        SharedDefaults.lastKnownWindLevel = newLevel.rawValue
                        logToFile("WindLevel CHANGED: \(lastKnownLevel) -> \(newLevel)")

                        // Check if should activate shield based on settings
                        // Don't activate if pet is already blown (100%)
                        let settings = SharedDefaults.limitSettings
                        let activationLevel = settings.shieldActivationLevel
                        logToFile("Settings: activationLevel=\(activationLevel?.rawValue ?? -1), notificationLevels=\(settings.notificationLevels.map { $0.rawValue })")

                        if let activationLevel = activationLevel,
                           newLevel.rawValue >= activationLevel.rawValue,
                           windPoints < 100 {
                            logToFile(">>> ACTIVATING SHIELD at level \(newLevel) (threshold: \(activationLevel))")
                            activateShield()
                        }

                        // Check if should send notification
                        if settings.notificationLevels.contains(newLevel) {
                            logToFile(">>> SENDING NOTIFICATION for level \(newLevel)")
                            sendWindLevelNotification(level: newLevel)
                        }
                    }
                } else {
                    logToFile("Skipping wind update: deltaSeconds=\(deltaSeconds) <= 0")
                }

                // Log snapshot with cumulative seconds
                logSnapshot(eventType: .usageThreshold(cumulativeSeconds: currentSeconds))

                // Final check: notify when absolute limit reached (100%)
                // Don't activate shield - pet is blown, no point blocking anymore
                let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
                logToFile("[Extension] limitSeconds=\(limitSeconds), checking if \(currentSeconds) >= \(limitSeconds)")
                if currentSeconds >= limitSeconds {
                    logToFile("[Extension] LIMIT REACHED (100%) - pet blown away")
                    sendLimitReachedNotification()
                }
            }
        }
    }

    /// Logs to shared file for debugging (extension can't print to console)
    private func logToFile(_ message: String) {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier) else { return }
        let logURL = containerURL.appendingPathComponent("extension_log.txt")
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "[\(timestamp)] \(message)\n"
        if let data = line.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logURL.path) {
                if let handle = try? FileHandle(forWritingTo: logURL) {
                    handle.seekToEndOfFile()
                    handle.write(data)
                    handle.closeFile()
                }
            } else {
                try? data.write(to: logURL)
            }
        }
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
        let content = UNMutableNotificationContent()
        content.title = "Screen Time Limit Reached"
        content.body = "Your pet is being blown away by the wind!"
        content.sound = .default
        content.userInfo = ["deepLink": "clif://shield"]
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "limitReached_\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }

    /// Sends notification when wind level changes
    private func sendWindLevelNotification(level: WindLevel) {
        let content = UNMutableNotificationContent()

        switch level {
        case .none:
            return // Don't notify for none
        case .low:
            content.title = "Vítr se zvedá"
            content.body = "Tvůj mazlíček cítí mírný vánek. Možná čas na přestávku?"
        case .medium:
            content.title = "Silnější vítr!"
            content.body = "Tvůj mazlíček se drží. Zvažuj zpomalení."
        case .high:
            content.title = "Nebezpečný vítr!"
            content.body = "Tvůj mazlíček je v ohrožení! Zastav se než bude pozdě."
        }

        content.sound = .default
        content.userInfo = ["deepLink": "clif://home"]
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "windLevel_\(level.rawValue)_\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logToFile("[Extension] Failed to send notification: \(error.localizedDescription)")
            } else {
                self?.logToFile("[Extension] WindLevel notification sent for level \(level)")
            }
        }
    }
}
