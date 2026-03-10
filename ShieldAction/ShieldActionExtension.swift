import Foundation
import ManagedSettings
import os.log

/// Shield Action Extension - handles button taps on the shield.
/// Based on: https://pedroesli.com/2023-11-13-screen-time-api/
///
/// IMPORTANT: Unlock is handled by redirecting user to main app via deep link.
/// The main app then handles wind decrease calculation and monitoring restart.
/// This is necessary because DeviceActivity thresholds are cumulative and cannot
/// be reset from extension - only from main app with full DeviceActivityCenter access.
class ShieldActionExtension: ShieldActionDelegate {

    let store = ManagedSettingsStore()
    let logger = Logger(subsystem: "com.janpodmolik.Uuumi.ShieldAction", category: "ShieldAction")

    // MARK: - Open Containing App

    /// Opens the containing app using LSApplicationWorkspace private API.
    /// Runs async to avoid blocking the shield UI. Should be called AFTER completionHandler.
    private func openContainingApp() {
        logToFile("openContainingApp() - dispatching async")

        DispatchQueue.global(qos: .userInitiated).async { [self] in
            guard let workspaceClass = NSClassFromString("LSApplicationWorkspace") else {
                logToFile("LSApplicationWorkspace not available")
                return
            }

            let defaultSelector = NSSelectorFromString("defaultWorkspace")
            guard workspaceClass.responds(to: defaultSelector),
                  let workspace = (workspaceClass as AnyObject).perform(defaultSelector)?.takeUnretainedValue() else {
                logToFile("Failed to get workspace instance")
                return
            }

            let openSelector = NSSelectorFromString("openApplicationWithBundleID:")
            guard workspace.responds(to: openSelector) else {
                logToFile("openApplicationWithBundleID: not available")
                return
            }

            logToFile("Opening app via LSApplicationWorkspace.openApplicationWithBundleID:")
            workspace.perform(openSelector, with: "com.janpodmolik.Uuumi")
            logToFile("openApplicationWithBundleID: completed")
        }
    }

    private func logToFile(_ message: String) {
        ExtensionLogger.log(message, prefix: "[ShieldAction]")
    }

    // MARK: - Day Start Shield Handling

    /// Checks if Day Start Shield is active.
    /// Returns true if handled (caller should call completionHandler(.defer) and then open the app).
    private var isDayStartShield: Bool {
        SharedDefaults.isDayStartShieldActive
    }

    /// Locks the wind preset for today (prevents changes).
    private func lockPresetForToday() {
        SharedDefaults.windPresetLockedForToday = true
        SharedDefaults.windPresetLockedDate = Date()
        logger.info("Wind preset locked for today")
    }

    // MARK: - Break Handling

    /// Checks if user is currently on a break and logs breakFailed if violated.
    private func handlePotentialBreakViolation() {
        // If there's an active break, opening a shielded app means break was violated
        guard let breakStartedAt = SharedDefaults.breakStartedAt,
              let petId = SharedDefaults.monitoredPetId else {
            return
        }

        let actualMinutes = Int(round(Date().timeIntervalSince(breakStartedAt) / 60))
        let windPoints = SharedDefaults.monitoredWindPoints

        let event = SnapshotEvent(
            petId: petId,
            windPoints: windPoints,
            eventType: .breakEnded(actualMinutes: actualMinutes, success: false)
        )

        SnapshotStore.shared.appendSync(event)
        SharedDefaults.breakStartedAt = nil

        logger.info("Break violated after \(actualMinutes) minutes - logged breakEnded(success: false)")
    }

    // MARK: - Unlock Handling

    /// Prepares unlock state (locks preset, checks break violation).
    /// Does NOT open the app — caller should call completionHandler first, then openContainingApp.
    private func prepareUnlock() {
        logToFile("prepareUnlock() - preparing state")
        logToFile("Current state: wind=\(SharedDefaults.monitoredWindPoints), isShieldActive=\(SharedDefaults.isShieldActive)")

        // Lock preset on first unlock of the day
        if !SharedDefaults.windPresetLockedForToday {
            lockPresetForToday()
        }

        // Check if this violates an active break
        handlePotentialBreakViolation()

        logToFile("prepareUnlock() - done")
    }

    // MARK: - ShieldActionDelegate

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        logToFile("handle(action:for APPLICATION) - action=\(action == .primaryButtonPressed ? "primary" : "secondary")")
        logToFile("Current state: wind=\(SharedDefaults.monitoredWindPoints), isShieldActive=\(SharedDefaults.isShieldActive), isDayStart=\(SharedDefaults.isDayStartShieldActive)")

        // Day Start Shield - redirect to preset picker
        if isDayStartShield {
            logToFile("Handled as Day Start Shield -> .defer")
            completionHandler(.defer)
            openContainingApp()
            return
        }

        switch action {
        case .primaryButtonPressed:
            logToFile("Primary button (Close App) pressed")
            completionHandler(.close)

        case .secondaryButtonPressed:
            logToFile("Secondary button (Unlock) pressed - redirecting to app")
            prepareUnlock()
            completionHandler(.defer)
            openContainingApp()

        @unknown default:
            logToFile("Unknown action - closing shield")
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        logger.info("handle(action:for webDomain:) called")

        if isDayStartShield {
            completionHandler(.defer)
            openContainingApp()
            return
        }

        switch action {
        case .primaryButtonPressed:
            logger.info("Primary button (Close App) pressed")
            completionHandler(.close)

        case .secondaryButtonPressed:
            logger.info("Secondary button (Unlock) pressed for web domain")
            prepareUnlock()
            completionHandler(.defer)
            openContainingApp()

        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        logger.info("handle(action:for category:) called")

        if isDayStartShield {
            completionHandler(.defer)
            openContainingApp()
            return
        }

        switch action {
        case .primaryButtonPressed:
            logger.info("Primary button (Close App) pressed")
            completionHandler(.close)

        case .secondaryButtonPressed:
            logger.info("Secondary button (Unlock) pressed for category")
            prepareUnlock()
            completionHandler(.defer)
            openContainingApp()

        @unknown default:
            completionHandler(.close)
        }
    }
}
