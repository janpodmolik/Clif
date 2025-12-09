import ManagedSettings
import ManagedSettingsUI
import os.log

/// Shield Action Extension - handles button taps on the shield.
/// Based on: https://pedroesli.com/2023-11-13-screen-time-api/
class ShieldActionExtension: ShieldActionDelegate {

    let store = ManagedSettingsStore()
    let logger = Logger(subsystem: "com.janpodmolik.Clif.ShieldAction", category: "ShieldAction")
    
    /// Unlocks an application - removes from shield or adds as exception
    private func unlockApplication(_ application: ApplicationToken) {
        // Method 1: Remove from direct application shield
        if store.shield.applications != nil {
            store.shield.applications?.remove(application)
        }
        
        // Method 2: If blocked via category, add this app as exception
        if let categories = store.shield.applicationCategories {
            switch categories {
            case .specific(let tokens, var exceptions):
                exceptions.insert(application)
                store.shield.applicationCategories = .specific(tokens, except: exceptions)
            case .all(var exceptions):
                exceptions.insert(application)
                store.shield.applicationCategories = .all(except: exceptions)
            @unknown default:
                break
            }
        }
    }

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            unlockApplication(application)
            // .defer keeps the app in foreground while shield updates
            // The shield should disappear once the app is no longer shielded
            completionHandler(.defer)

        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for webDomain: WebDomainToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            store.shield.webDomains?.remove(webDomain)
            completionHandler(.defer)

        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        switch action {
        case .primaryButtonPressed:
            // Remove the entire category from shield
            if let categories = store.shield.applicationCategories {
                if case .specific(var tokens, let exceptions) = categories {
                    tokens.remove(category)
                    if tokens.isEmpty {
                        store.shield.applicationCategories = nil
                    } else {
                        store.shield.applicationCategories = .specific(tokens, except: exceptions)
                    }
                }
            }
            completionHandler(.defer)

        case .secondaryButtonPressed:
            completionHandler(.close)
        @unknown default:
            completionHandler(.close)
        }
    }
}
