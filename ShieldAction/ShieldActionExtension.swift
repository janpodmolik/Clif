import ManagedSettings
import UserNotifications
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
    let logger = Logger(subsystem: "com.janpodmolik.Clif.ShieldAction", category: "ShieldAction")

    private func logToFile(_ message: String) {
        ExtensionLogger.log(message, prefix: "[ShieldAction]")
    }

    // MARK: - Notifications

    /// Sends notification with custom deeplink.
    private func sendNotificationWithDeepLink(title: String, body: String, deepLink: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil
        content.userInfo = ["deepLink": deepLink]
        content.interruptionLevel = .timeSensitive

        let request = UNNotificationRequest(
            identifier: "clif-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to send notification: \(error.localizedDescription)")
            }
        }
    }

    /// Sends blow away notification.
    private func sendBlowAwayNotification() {
        WindNotification.blowAway.send { [weak self] message in
            self?.logToFile(message)
        }
    }

    // MARK: - Morning Shield Handling

    /// Handles Morning Shield unlock - locks preset for the day.
    /// Returns the ShieldActionResponse to use, or nil if this is not a Morning Shield action.
    private func handleMorningShieldAction(action: ShieldAction) -> ShieldActionResponse? {
        guard SharedDefaults.isMorningShieldActive else {
            return nil
        }

        // Safety check: if wind is not 0, morning shield shouldn't be active
        // This handles edge cases where state got out of sync
        if SharedDefaults.monitoredWindPoints > 0 {
            logger.info("Morning Shield: Wind is \(SharedDefaults.monitoredWindPoints), deactivating morning shield")
            SharedDefaults.isMorningShieldActive = false
            return nil // Fall through to normal shield handling
        }

        switch action {
        case .primaryButtonPressed:
            // "Otevřít Clif" - send notification with deeplink to preset picker
            logger.info("Morning Shield: Primary button - opening app for preset selection")
            sendNotificationWithDeepLink(
                title: "Vyber si náročnost dne",
                body: "Nastav jak náročný den chceš mít",
                deepLink: DeepLinks.presetPicker
            )
            return .close

        case .secondaryButtonPressed:
            // "Pokračovat s [preset]" - use yesterday's preset, deactivate morning shield, stay in app
            logger.info("Morning Shield: Secondary button - continuing with current preset, staying in app")
            lockPresetForToday()
            deactivateMorningShield()
            // No notification needed - user stays in the app they wanted to open
            return .defer

        @unknown default:
            return nil
        }
    }

    /// Locks the wind preset for today (prevents changes).
    private func lockPresetForToday() {
        SharedDefaults.windPresetLockedForToday = true
        SharedDefaults.windPresetLockedDate = Date()
        logger.info("Wind preset locked for today")
    }

    /// Deactivates morning shield and clears shields.
    private func deactivateMorningShield() {
        logToFile("deactivateMorningShield() START")
        logToFile("Before: isShieldActive=\(SharedDefaults.isShieldActive), isMorningShieldActive=\(SharedDefaults.isMorningShieldActive)")

        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        SharedDefaults.resetShieldFlags()
        SharedDefaults.synchronize()

        logToFile("After: isShieldActive=\(SharedDefaults.isShieldActive), isMorningShieldActive=\(SharedDefaults.isMorningShieldActive)")
        logToFile("deactivateMorningShield() END")
    }

    // MARK: - Break Handling

    /// Checks if user is currently on a break and logs breakFailed if violated.
    private func handlePotentialBreakViolation() {
        // If there's an active break, opening a shielded app means break was violated
        guard let breakStartedAt = SharedDefaults.breakStartedAt,
              let petId = SharedDefaults.monitoredPetId else {
            return
        }

        let actualMinutes = Int(Date().timeIntervalSince(breakStartedAt) / 60)
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

    /// Handles unlock request by sending notification to open main app.
    /// Shield stays active - user must explicitly unlock in the app.
    private func handleUnlockRequest() {
        logToFile("handleUnlockRequest() - sending notification to open app")
        logToFile("Current state: wind=\(SharedDefaults.monitoredWindPoints), isShieldActive=\(SharedDefaults.isShieldActive)")

        // Lock preset on first unlock of the day
        if !SharedDefaults.windPresetLockedForToday {
            lockPresetForToday()
        }

        // Check if this violates an active break
        handlePotentialBreakViolation()

        // Send notification to open app - shield stays active until user unlocks in app
        sendNotificationWithDeepLink(
            title: "Odemknout aplikace",
            body: "Klepni pro otevření Clif a odemčení",
            deepLink: DeepLinks.home
        )

        logToFile("handleUnlockRequest() - notification sent, shield stays active")
    }

    // MARK: - ShieldActionDelegate

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        logToFile("handle(action:for APPLICATION) - action=\(action == .primaryButtonPressed ? "primary" : "secondary")")
        logToFile("Current state: wind=\(SharedDefaults.monitoredWindPoints), isShieldActive=\(SharedDefaults.isShieldActive), isMorning=\(SharedDefaults.isMorningShieldActive)")

        // Check if this is Morning Shield
        if let response = handleMorningShieldAction(action: action) {
            logToFile("Handled as Morning Shield -> response=\(response == .close ? "close" : "defer")")
            completionHandler(response)
            return
        }

        switch action {
        case .primaryButtonPressed:
            logToFile("Primary button (Close App) pressed")
            sendNotificationWithDeepLink(
                title: "Otevřít Clif",
                body: "Klepni pro zobrazení peta",
                deepLink: DeepLinks.home
            )
            completionHandler(.close)

        case .secondaryButtonPressed:
            logToFile("Secondary button (Unlock) pressed - redirecting to app")
            handleUnlockRequest()
            completionHandler(.close)

        @unknown default:
            logToFile("Unknown action - closing shield")
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        logger.info("handle(action:for webDomain:) called")

        // Check if this is Morning Shield
        if let response = handleMorningShieldAction(action: action) {
            completionHandler(response)
            return
        }

        switch action {
        case .primaryButtonPressed:
            logger.info("Primary button (Close App) pressed")
            sendNotificationWithDeepLink(
                title: "Otevřít Clif",
                body: "Klepni pro zobrazení peta",
                deepLink: DeepLinks.home
            )
            completionHandler(.close)

        case .secondaryButtonPressed:
            logger.info("Secondary button (Unlock) pressed for web domain")
            handleUnlockRequest()
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        logger.info("handle(action:for category:) called")

        // Check if this is Morning Shield
        if let response = handleMorningShieldAction(action: action) {
            completionHandler(response)
            return
        }

        switch action {
        case .primaryButtonPressed:
            logger.info("Primary button (Close App) pressed")
            sendNotificationWithDeepLink(
                title: "Otevřít Clif",
                body: "Klepni pro zobrazení peta",
                deepLink: DeepLinks.home
            )
            completionHandler(.close)

        case .secondaryButtonPressed:
            logger.info("Secondary button (Unlock) pressed for category")
            handleUnlockRequest()
            completionHandler(.close)

        @unknown default:
            completionHandler(.close)
        }
    }
}
