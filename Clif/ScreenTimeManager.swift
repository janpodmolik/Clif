import Foundation
import Combine
import FamilyControls
import DeviceActivity
import ManagedSettings
import os.log

private let log = Logger(subsystem: AppConstants.loggingSubsystem, category: "ScreenTimeManager")

extension DeviceActivityName {
    static let daily = DeviceActivityName("daily")
}

/// Manages Screen Time authorization, app selection, and device activity monitoring
final class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()
    
    @Published var activitySelection = FamilyActivitySelection()
    @Published var isAuthorized = false
    
    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore()
    
    private init() {
        if let savedSelection = SharedDefaults.selection {
            self.activitySelection = savedSelection
        }
        
        Task {
            await checkAuthorization()
        }
    }
    
    // MARK: - Authorization
    
    @MainActor
    func requestAuthorization() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            self.isAuthorized = true
            log.info("✅ Screen Time authorization granted")
        } catch {
            log.error("❌ Authorization failed: \(error.localizedDescription)")
            self.isAuthorized = false
        }
    }
    
    @MainActor
    func checkAuthorization() async {
        self.isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }
    
    // MARK: - Selection
    
    func saveSelection() {
        SharedDefaults.selection = activitySelection
        startMonitoring()
    }
    
    // MARK: - Shield Management
    
    func updateShield() {
        store.shield.applications = activitySelection.applicationTokens
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(
            activitySelection.categoryTokens,
            except: Set()
        )
        store.shield.webDomains = activitySelection.webDomainTokens
        log.info("🛡️ Shield applied")
    }
    
    func clearShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        log.info("🛡️ Shield cleared")
    }
    
    // MARK: - Monitoring
    
    func startMonitoring() {
        let limitMinutes = SharedDefaults.dailyLimitMinutes
        let limitSeconds = limitMinutes * 60
        
        let appCount = activitySelection.applicationTokens.count
        let catCount = activitySelection.categoryTokens.count
        let webCount = activitySelection.webDomainTokens.count
        
        guard appCount > 0 || catCount > 0 || webCount > 0 else {
            log.warning("⚠️ No apps/categories selected, skipping monitoring")
            return
        }
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        
        // Create 10 thresholds (10% to 100%)
        for i in 1...10 {
            let percentage = i * 10
            let thresholdSeconds = max(AppConstants.minimumThresholdSeconds, (limitSeconds * percentage) / 100)
            let eventName = DeviceActivityEvent.Name("threshold_\(percentage)")
            
            events[eventName] = DeviceActivityEvent(
                applications: activitySelection.applicationTokens,
                categories: activitySelection.categoryTokens,
                webDomains: activitySelection.webDomainTokens,
                threshold: DateComponents(minute: thresholdSeconds / 60, second: thresholdSeconds % 60)
            )
        }
        
        do {
            center.stopMonitoring()
            try center.startMonitoring(.daily, during: schedule, events: events)
            log.info("✅ Monitoring started: \(limitMinutes)min limit, \(appCount) apps, \(catCount) categories")
        } catch {
            log.error("❌ Failed to start monitoring: \(error.localizedDescription)")
        }
    }
}
