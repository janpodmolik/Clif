import Foundation
import Combine
import FamilyControls
import DeviceActivity
import ManagedSettings

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

    /// Task for debouncing selection saves
    private var saveSelectionTask: Task<Void, Never>?

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
        } catch {
            self.isAuthorized = false
        }
    }
    
    @MainActor
    func checkAuthorization() async {
        self.isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }
    
    // MARK: - Selection

    /// Saves selection with debouncing to prevent rapid successive calls
    /// when user toggles multiple apps quickly
    func saveSelection() {
        saveSelectionTask?.cancel()
        saveSelectionTask = Task {
            // Debounce before actually saving
            try? await Task.sleep(nanoseconds: AppConstants.selectionDebounceNanoseconds)
            guard !Task.isCancelled else { return }

            await MainActor.run {
                performSaveSelection()
            }
        }
    }

    /// Immediately saves selection without debouncing (for programmatic use)
    private func performSaveSelection() {
        SharedDefaults.selection = activitySelection
        // Also save tokens separately for lightweight extension access
        SharedDefaults.saveTokens(from: activitySelection)
        // Clear any existing shields before starting fresh monitoring
        clearShield()
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
    }
    
    func clearShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }
    
    // MARK: - Monitoring
    
    func startMonitoring() {
        let limitMinutes = SharedDefaults.dailyLimitMinutes
        let limitSeconds = limitMinutes * 60
        
        let appCount = activitySelection.applicationTokens.count
        let catCount = activitySelection.categoryTokens.count
        let webCount = activitySelection.webDomainTokens.count
        
        guard appCount > 0 || catCount > 0 || webCount > 0 else {
            return
        }
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
        // Track only meaningful thresholds to reduce churn
        let checkpoints = AppConstants.monitoringThresholds
        
        for percentage in checkpoints {
            let thresholdSeconds = max(AppConstants.minimumThresholdSeconds, (limitSeconds * percentage) / 100)
            let eventName = DeviceActivityEvent.Name("threshold_\(percentage)")
            
            events[eventName] = DeviceActivityEvent(
                applications: activitySelection.applicationTokens,
                categories: activitySelection.categoryTokens,
                webDomains: activitySelection.webDomainTokens,
                threshold: DateComponents(minute: thresholdSeconds / 60, second: thresholdSeconds % 60)
            )
        }
        
        // Add 11th event: "1 minute remaining" notification
        let oneMinuteBeforeLimitSeconds = max(0, limitSeconds - 60)
        if oneMinuteBeforeLimitSeconds > 0 {
            let lastMinuteEventName = DeviceActivityEvent.Name("lastMinute")
            events[lastMinuteEventName] = DeviceActivityEvent(
                applications: activitySelection.applicationTokens,
                categories: activitySelection.categoryTokens,
                webDomains: activitySelection.webDomainTokens,
                threshold: DateComponents(minute: oneMinuteBeforeLimitSeconds / 60, second: oneMinuteBeforeLimitSeconds % 60)
            )
        }
        
        do {
            center.stopMonitoring()
            try center.startMonitoring(.daily, during: schedule, events: events)
            #if DEBUG
            print("[ScreenTimeManager] Started monitoring with \(events.count) events")
            #endif
        } catch {
            #if DEBUG
            print("[ScreenTimeManager] Failed to start monitoring: \(error.localizedDescription)")
            #endif
        }
    }
}
