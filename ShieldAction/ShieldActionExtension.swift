import DeviceActivity
import ManagedSettings
import UserNotifications
import os.log

/// Shield Action Extension - handles button taps on the shield.
/// Based on: https://pedroesli.com/2023-11-13-screen-time-api/
class ShieldActionExtension: ShieldActionDelegate {

    let store = ManagedSettingsStore()
    let center = DeviceActivityCenter()
    let logger = Logger(subsystem: "com.janpodmolik.Clif.ShieldAction", category: "ShieldAction")

    private func logToFile(_ message: String) {
        ExtensionLogger.log(message, prefix: "[ShieldAction]")
    }

    // MARK: - Notifications

    /// Sends a notification to open the Clif app.
    /// Note: Direct app opening from ShieldActionDelegate is not supported by Apple.
    /// See: https://developer.apple.com/forums/thread/719905
    private func sendNotification(title: String, body: String = "") {
        logger.info("sendNotification() called - title: \(title)")

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil // Silent - less intrusive
        content.userInfo = ["deepLink": DeepLinks.shield]
        content.interruptionLevel = .timeSensitive // Bypass Focus modes

        let request = UNNotificationRequest(
            identifier: "clif-\(UUID().uuidString)",
            content: content,
            trigger: nil // nil = immediate
        )

        UNUserNotificationCenter.current().add(request) { [weak self] error in
            if let error = error {
                self?.logger.error("Failed to send notification: \(error.localizedDescription)")
            } else {
                self?.logger.info("Notification sent successfully")
            }
        }
    }

    // MARK: - Unlock Methods

    /// Clears all shields - unlocks all limited sources at once.
    /// Called when user taps "Unlock" on any shielded app/category/web domain.
    private func clearAllShields() {
        logToFile("clearAllShields() START")
        logToFile("Before: isShieldActive=\(SharedDefaults.isShieldActive), isMorningShieldActive=\(SharedDefaults.isMorningShieldActive)")
        logToFile("Before: windPoints=\(SharedDefaults.monitoredWindPoints), lastThreshold=\(SharedDefaults.monitoredLastThresholdSeconds)")

        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        SharedDefaults.resetShieldFlags()
        SharedDefaults.synchronize()

        logToFile("After: isShieldActive=\(SharedDefaults.isShieldActive), isMorningShieldActive=\(SharedDefaults.isMorningShieldActive)")
        logToFile("clearAllShields() END - shields cleared, flags reset")
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
            sendNotification(title: "Tap to open Clif")
            completionHandler(.close)

        case .secondaryButtonPressed:
            logToFile("Secondary button (Unlock) pressed - will clear all shields")

            // Lock preset on first unlock of the day
            if !SharedDefaults.windPresetLockedForToday {
                lockPresetForToday()
            }

            // Check if this violates an active break
            handlePotentialBreakViolation()

            clearAllShields()
            sendNotification(title: "Shields cleared", body: "Tap to track in Clif")
            logToFile("Returning .defer - user should stay in app")
            completionHandler(.defer)

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
            sendNotification(title: "Tap to open Clif")
            completionHandler(.close)

        case .secondaryButtonPressed:
            logger.info("Secondary button (Unlock) pressed for web domain - unlocking all")

            // Lock preset on first unlock of the day
            if !SharedDefaults.windPresetLockedForToday {
                lockPresetForToday()
            }

            handlePotentialBreakViolation()
            clearAllShields()
            sendNotification(title: "Shields cleared", body: "Tap to track in Clif")
            completionHandler(.defer)

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
            sendNotification(title: "Tap to open Clif")
            completionHandler(.close)

        case .secondaryButtonPressed:
            logger.info("Secondary button (Unlock) pressed for category - unlocking all")

            // Lock preset on first unlock of the day
            if !SharedDefaults.windPresetLockedForToday {
                lockPresetForToday()
            }

            handlePotentialBreakViolation()
            clearAllShields()
            sendNotification(title: "Shields cleared", body: "Tap to track in Clif")
            completionHandler(.defer)

        @unknown default:
            completionHandler(.close)
        }
    }
}
