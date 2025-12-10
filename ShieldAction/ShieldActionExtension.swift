import ManagedSettings
import UserNotifications
import os.log

/// Shield Action Extension - handles button taps on the shield.
/// Based on: https://pedroesli.com/2023-11-13-screen-time-api/
class ShieldActionExtension: ShieldActionDelegate {

    let store = ManagedSettingsStore()
    let logger = Logger(subsystem: "com.janpodmolik.Clif.ShieldAction", category: "ShieldAction")

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
        content.userInfo = ["deepLink": "clif://shield"]
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

    /// Unlocks an application - removes from shield or adds as exception
    private func unlockApplication(_ application: ApplicationToken) {
        logger.info("unlockApplication() called")

        // Method 1: Remove from direct application shield
        if store.shield.applications != nil {
            store.shield.applications?.remove(application)
            logger.info("Removed app from shield.applications")
        }

        // Method 2: If blocked via category, add this app as exception
        if let categories = store.shield.applicationCategories {
            switch categories {
            case .specific(let tokens, var exceptions):
                exceptions.insert(application)
                store.shield.applicationCategories = .specific(tokens, except: exceptions)
                logger.info("Added app as exception to specific categories")
            case .all(var exceptions):
                exceptions.insert(application)
                store.shield.applicationCategories = .all(except: exceptions)
                logger.info("Added app as exception to all categories")
            @unknown default:
                break
            }
        }
    }

    /// Unlocks a web domain - removes from shield
    private func unlockWebDomain(_ webDomain: WebDomainToken) {
        logger.info("unlockWebDomain() called")
        store.shield.webDomains?.remove(webDomain)
    }

    /// Unlocks a category - removes from shield
    private func unlockCategory(_ category: ActivityCategoryToken) {
        logger.info("unlockCategory() called")
        if let categories = store.shield.applicationCategories {
            if case .specific(var tokens, let exceptions) = categories {
                tokens.remove(category)
                if tokens.isEmpty {
                    store.shield.applicationCategories = nil
                    logger.info("Removed last category, set applicationCategories to nil")
                } else {
                    store.shield.applicationCategories = .specific(tokens, except: exceptions)
                    logger.info("Removed category from specific categories")
                }
            }
        }
    }

    // MARK: - ShieldActionDelegate

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        logger.info("handle(action:for application:) called")

        switch action {
        case .primaryButtonPressed:
            // Close App - closes the blocked app, returns to home screen
            logger.info("Primary button (Close App) pressed")
            sendNotification(title: "Tap to open Clif")
            completionHandler(.close)

        case .secondaryButtonPressed:
            // Unlock - removes shield from this app, user stays in app
            logger.info("Secondary button (Unlock) pressed - unlocking app")
            unlockApplication(application)
            sendNotification(title: "App unlocked", body: "Tap to track in Clif")
            completionHandler(.defer) // .defer keeps user in app after unlock

        @unknown default:
            logger.info("Unknown action - closing shield")
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        logger.info("handle(action:for webDomain:) called")

        switch action {
        case .primaryButtonPressed:
            logger.info("Primary button (Close App) pressed")
            sendNotification(title: "Tap to open Clif")
            completionHandler(.close)

        case .secondaryButtonPressed:
            logger.info("Secondary button (Unlock) pressed for web domain")
            unlockWebDomain(webDomain)
            sendNotification(title: "Web domain unlocked", body: "Tap to track in Clif")
            completionHandler(.defer)

        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        logger.info("handle(action:for category:) called")

        switch action {
        case .primaryButtonPressed:
            logger.info("Primary button (Close App) pressed")
            sendNotification(title: "Tap to open Clif")
            completionHandler(.close)

        case .secondaryButtonPressed:
            logger.info("Secondary button (Unlock) pressed for category")
            unlockCategory(category)
            sendNotification(title: "Category unlocked", body: "Tap to track in Clif")
            completionHandler(.defer)

        @unknown default:
            completionHandler(.close)
        }
    }
}
