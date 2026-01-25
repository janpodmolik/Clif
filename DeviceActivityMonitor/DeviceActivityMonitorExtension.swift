import DeviceActivity
import Foundation

/// Background extension that monitors device activity and updates wind.
/// Runs in a separate process with limited memory (~6MB).
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    // MARK: - DeviceActivityMonitor Overrides

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)

        logToFile("[Extension] intervalDidStart")

        // Check if this is actually a new day or just a monitoring restart
        let existingWindPoints = SharedDefaults.monitoredWindPoints
        let existingThreshold = SharedDefaults.monitoredLastThresholdSeconds

        if existingWindPoints > 0 || existingThreshold > 0 {
            // Monitoring restart (not new day) - save current cumulative as baseline
            // iOS resets its internal counter to 0 on restart, so we need to remember
            // how much time was already accumulated before the restart
            let oldBaseline = SharedDefaults.cumulativeBaseline
            let newBaseline = oldBaseline + existingThreshold
            SharedDefaults.cumulativeBaseline = newBaseline
            SharedDefaults.monitoredLastThresholdSeconds = 0

            logToFile("[Extension] Skipped reset - existing wind: \(existingWindPoints), threshold: \(existingThreshold)")
            logToFile("[Extension] Baseline updated: \(oldBaseline) + \(existingThreshold) = \(newBaseline)")
            return
        }

        // Reset wind state for new day
        SharedDefaults.resetWindState()

        logToFile("[Extension] Day reset complete")
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
        logToFile("isShieldActive=\(isShieldActive)")

        if isShieldActive {
            logToFile("Skipping wind - shield active")
            return false
        }

        return true
    }

    /// Threshold processing - calculate wind and log.
    /// Uses WindCalculator for absolute formula: wind = (cumulativeSeconds - breakReduction) / limitSeconds * 100
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

        // Use WindCalculator for consistent wind calculation
        let newWindPoints = WindCalculator.calculate(
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
    }

    private func logToFile(_ message: String) {
        ExtensionLogger.log(message)
    }
}
