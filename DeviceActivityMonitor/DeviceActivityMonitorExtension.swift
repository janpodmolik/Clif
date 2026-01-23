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

        // Clear shields at start of new day
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        // Reset wind state for new day
        SharedDefaults.currentProgress = 0
        SharedDefaults.monitoredWindPoints = 0
        SharedDefaults.monitoredLastThresholdSeconds = 0

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
            logToFile("[Extension] eventDidReachThreshold: \(eventName)")

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

                logToFile("[Extension] seconds=\(currentSeconds), lastSeconds=\(lastSeconds), delta=\(deltaSeconds), riseRate=\(riseRatePerSecond)/s, oldWind=\(oldWindPoints)")

                if deltaSeconds > 0 {
                    var windPoints = oldWindPoints
                    windPoints += Double(deltaSeconds) * riseRatePerSecond
                    windPoints = min(windPoints, 100)

                    // Update SharedDefaults so main app can read it
                    SharedDefaults.monitoredWindPoints = windPoints
                    SharedDefaults.monitoredLastThresholdSeconds = currentSeconds

                    logToFile("[Extension] Updated wind: \(oldWindPoints) -> \(windPoints)")
                }

                // Log snapshot with cumulative seconds
                logSnapshot(eventType: .usageThreshold(cumulativeSeconds: currentSeconds))

                // Activate shield when limit reached
                let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
                logToFile("[Extension] limitSeconds=\(limitSeconds), checking if \(currentSeconds) >= \(limitSeconds)")
                if currentSeconds >= limitSeconds {
                    logToFile("[Extension] LIMIT REACHED - activating shield")
                    activateShield()
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
            // Use lightweight token loading instead of full FamilyActivitySelection decode
            if let appTokens = SharedDefaults.loadApplicationTokens(), !appTokens.isEmpty {
                store.shield.applications = appTokens
            }

            if let catTokens = SharedDefaults.loadCategoryTokens(), !catTokens.isEmpty {
                store.shield.applicationCategories = .specific(catTokens, except: Set())
            }

            if let webTokens = SharedDefaults.loadWebDomainTokens(), !webTokens.isEmpty {
                store.shield.webDomains = webTokens
            }
        }
    }

    /// Sends notification when screen time limit is reached
    private func sendLimitReachedNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Screen Time Limit Reached"
        content.body = "Your pet is being blown away by the wind!"
        content.sound = .default
        content.userInfo = ["deepLink": "clif://shield"]

        let request = UNNotificationRequest(
            identifier: "limitReached_\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }
}
