//
//  DeviceActivityMonitorExtension.swift
//  DeviceActivityMonitor
//
//  Created by Jan Podmolík on 07.12.2025.
//

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
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        
        let eventName = event.rawValue
        
        // Parse threshold percentage from event name "threshold_X"
        if eventName.hasPrefix("threshold_"),
           let valueString = eventName.split(separator: "_").last,
           let thresholdValue = Int(valueString) {
            
            SharedDefaults.currentProgress = thresholdValue
            
            // Activate shield at 90% or 100%
            if thresholdValue >= 90 {
                activateShield()
            }
            
            // Send notification at 90% (only once)
            if thresholdValue == 90 && !SharedDefaults.notification90Sent {
                sendNotification(
                    title: "90% Screen Time Used",
                    body: "You're approaching your daily limit."
                )
                SharedDefaults.notification90Sent = true
            }
            return
        }
        
        // Handle "lastMinute" event
        if eventName == "lastMinute" && !SharedDefaults.notificationLastMinuteSent {
            sendNotification(
                title: "1 Minute Remaining",
                body: "Your screen time limit is almost up."
            )
            SharedDefaults.notificationLastMinuteSent = true
            return
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
