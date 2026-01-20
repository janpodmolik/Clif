import DeviceActivity
import FamilyControls
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

        // Reset progress
        SharedDefaults.currentProgress = 0
        SharedDefaults.notification90Sent = false
        SharedDefaults.notificationLastMinuteSent = false

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

            // Daily mode: Parse threshold percentage from event name "threshold_X"
            if eventName.hasPrefix("threshold_"),
               let valueString = eventName.split(separator: "_").last,
               let thresholdValue = Int(valueString) {

                SharedDefaults.currentProgress = thresholdValue

                // Calculate cumulative minutes from percentage
                let limitMinutes = SharedDefaults.dailyLimitMinutes
                let cumulativeMinutes = (thresholdValue * limitMinutes) / 100

                // Log snapshot
                logSnapshot(eventType: .usageThreshold(cumulativeMinutes: cumulativeMinutes))

                // Activate shield at shieldActivationPercentage or higher
                if thresholdValue >= AppConstants.shieldActivationPercentage {
                    activateShield()
                }

                // Send notification at shieldActivationPercentage (only once)
                if thresholdValue == AppConstants.shieldActivationPercentage && !SharedDefaults.notification90Sent {
                    sendNotification(
                        title: "90% Screen Time Used",
                        body: "You're approaching your daily limit."
                    )
                    SharedDefaults.notification90Sent = true
                }
                return
            }

            // Dynamic mode: Parse minute from event name "minute_X"
            if eventName.hasPrefix("minute_"),
               let valueString = eventName.split(separator: "_").last,
               let minute = Int(valueString) {

                // Log snapshot with cumulative minutes
                logSnapshot(eventType: .usageThreshold(cumulativeMinutes: minute))

                // Activate shield when limit reached (last threshold)
                let limitMinutes = SharedDefaults.dailyLimitMinutes
                if minute >= limitMinutes {
                    activateShield()
                }
                return
            }

            // Handle "lastMinute" event (Daily mode only)
            if eventName == "lastMinute" && !SharedDefaults.notificationLastMinuteSent {
                sendNotification(
                    title: "1 Minute Remaining",
                    body: "Your screen time limit is almost up."
                )
                SharedDefaults.notificationLastMinuteSent = true
            }
        }
    }

    // MARK: - Snapshot Logging

    private func logSnapshot(eventType: SnapshotEventType) {
        autoreleasepool {
            guard let petId = SharedDefaults.monitoredPetId,
                  let mode = SharedDefaults.monitoredPetMode else {
                return
            }

            let windPoints = SharedDefaults.monitoredWindPoints

            let event = SnapshotEvent(
                petId: petId,
                mode: mode,
                windPoints: windPoints,
                eventType: eventType
            )

            SnapshotStore.shared.appendSync(event)
        }
    }
    
    // MARK: - Helpers
    
    /// Sends a local notification
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
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
}
