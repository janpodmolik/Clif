import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

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

            // Parse minute from event name "minute_X"
            if eventName.hasPrefix("minute_"),
               let valueString = eventName.split(separator: "_").last,
               let minute = Int(valueString) {

                // Log snapshot with cumulative minutes
                logSnapshot(eventType: .usageThreshold(cumulativeMinutes: minute))

                // Activate shield when limit reached (last threshold = minutesToBlowAway)
                let limitMinutes = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitMinutes)
                if minute >= limitMinutes {
                    activateShield()
                }
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
}
