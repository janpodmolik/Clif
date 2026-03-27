import Foundation
import ManagedSettings

/// Shield Action Extension - handles button taps on the shield.
///
/// IMPORTANT: Unlock is handled by redirecting user to main app via deep link.
/// The main app then handles wind decrease calculation and monitoring restart.
/// This is necessary because DeviceActivity thresholds are cumulative and cannot
/// be reset from extension - only from main app with full DeviceActivityCenter access.
class ShieldActionExtension: ShieldActionDelegate {

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
        logToFile("Wind preset locked for today")
    }

    // MARK: - Unlock Handling

    /// Prepares unlock state (locks preset, signals main app).
    /// Does NOT open the app — caller should call completionHandler first, then openContainingApp.
    /// Break handling is left to the main app when user taps the lock button.
    private func prepareUnlock() {
        logToFile("prepareUnlock() - preparing state")
        logToFile("Current state: wind=\(SharedDefaults.monitoredWindPoints), isShieldActive=\(SharedDefaults.isShieldActive)")

        // Lock preset on first unlock of the day
        if !SharedDefaults.windPresetLockedForToday {
            lockPresetForToday()
        }

        // Signal main app to highlight the unlock button
        SharedDefaults.pendingShieldUnlock = true

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
        logToFile("handle(action:for WEB DOMAIN) - action=\(action == .primaryButtonPressed ? "primary" : "secondary")")

        if isDayStartShield {
            logToFile("Handled as Day Start Shield -> .defer")
            completionHandler(.defer)
            openContainingApp()
            return
        }

        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)

        case .secondaryButtonPressed:
            logToFile("Unlock pressed - redirecting to app")
            prepareUnlock()
            completionHandler(.defer)
            openContainingApp()

        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        logToFile("handle(action:for CATEGORY) - action=\(action == .primaryButtonPressed ? "primary" : "secondary")")

        if isDayStartShield {
            logToFile("Handled as Day Start Shield -> .defer")
            completionHandler(.defer)
            openContainingApp()
            return
        }

        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)

        case .secondaryButtonPressed:
            logToFile("Unlock pressed - redirecting to app")
            prepareUnlock()
            completionHandler(.defer)
            openContainingApp()

        @unknown default:
            completionHandler(.close)
        }
    }
}
