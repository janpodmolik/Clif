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

    /// Starts monitoring for a specific pet. Updates SharedDefaults with monitoring context.
    /// - Parameters:
    ///   - petId: UUID of the pet being monitored
    ///   - mode: Pet mode (daily or dynamic)
    ///   - limitMinutes: Screen time limit in minutes
    ///   - windPoints: Current wind points for snapshot logging
    func startMonitoring(petId: UUID, mode: PetMode, limitMinutes: Int, windPoints: Double) {
        let limitSeconds = limitMinutes * 60

        let appCount = activitySelection.applicationTokens.count
        let catCount = activitySelection.categoryTokens.count
        let webCount = activitySelection.webDomainTokens.count

        guard appCount > 0 || catCount > 0 || webCount > 0 else {
            return
        }

        // Update monitoring context for extensions
        SharedDefaults.monitoredPetId = petId
        SharedDefaults.monitoredPetMode = mode
        SharedDefaults.monitoredWindPoints = windPoints
        SharedDefaults.dailyLimitMinutes = limitMinutes

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let events = buildEvents(for: mode, limitSeconds: limitSeconds)

        do {
            center.stopMonitoring()
            try center.startMonitoring(.daily, during: schedule, events: events)
            #if DEBUG
            print("[ScreenTimeManager] Started \(mode.rawValue) monitoring with \(events.count) events for pet \(petId)")
            #endif
        } catch {
            #if DEBUG
            print("[ScreenTimeManager] Failed to start monitoring: \(error.localizedDescription)")
            #endif
        }
    }

    /// Legacy method for backwards compatibility. Uses Daily mode with default limit.
    func startMonitoring() {
        let limitMinutes = SharedDefaults.dailyLimitMinutes
        let petId = SharedDefaults.monitoredPetId ?? UUID()
        let mode = SharedDefaults.monitoredPetMode ?? .daily
        let windPoints = SharedDefaults.monitoredWindPoints

        startMonitoring(petId: petId, mode: mode, limitMinutes: limitMinutes, windPoints: windPoints)
    }

    /// Stops all monitoring and clears monitoring context.
    func stopMonitoring() {
        center.stopMonitoring()
        SharedDefaults.monitoredPetId = nil
        SharedDefaults.monitoredPetMode = nil
        #if DEBUG
        print("[ScreenTimeManager] Stopped monitoring")
        #endif
    }

    // MARK: - Event Building

    private func buildEvents(for mode: PetMode, limitSeconds: Int) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        switch mode {
        case .daily:
            return buildDailyEvents(limitSeconds: limitSeconds)
        case .dynamic:
            return buildDynamicEvents(limitSeconds: limitSeconds)
        }
    }

    /// Daily mode: percentage thresholds + "1 minute before limit"
    private func buildDailyEvents(limitSeconds: Int) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        for percentage in AppConstants.dailyThresholdPercentages {
            let thresholdSeconds = max(AppConstants.minimumThresholdSeconds, (limitSeconds * percentage) / 100)
            let eventName = DeviceActivityEvent.Name("threshold_\(percentage)")

            events[eventName] = DeviceActivityEvent(
                applications: activitySelection.applicationTokens,
                categories: activitySelection.categoryTokens,
                webDomains: activitySelection.webDomainTokens,
                threshold: DateComponents(minute: thresholdSeconds / 60, second: thresholdSeconds % 60)
            )
        }

        // "1 minute remaining" event
        let oneMinuteBeforeLimitSeconds = max(0, limitSeconds - 60)
        if oneMinuteBeforeLimitSeconds > 0 {
            events[DeviceActivityEvent.Name("lastMinute")] = DeviceActivityEvent(
                applications: activitySelection.applicationTokens,
                categories: activitySelection.categoryTokens,
                webDomains: activitySelection.webDomainTokens,
                threshold: DateComponents(minute: oneMinuteBeforeLimitSeconds / 60, second: oneMinuteBeforeLimitSeconds % 60)
            )
        }

        return events
    }

    /// Dynamic mode: per-minute thresholds for granular windPoints tracking
    private func buildDynamicEvents(limitSeconds: Int) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        let limitMinutes = limitSeconds / 60

        // Create threshold for each minute (1, 2, 3, ..., limitMinutes)
        // Cap at maxDynamicThresholds due to DeviceActivity API limit
        let maxThresholds = min(limitMinutes, AppConstants.maxDynamicThresholds)

        for minute in 1...maxThresholds {
            let thresholdSeconds = minute * 60
            let eventName = DeviceActivityEvent.Name("minute_\(minute)")

            events[eventName] = DeviceActivityEvent(
                applications: activitySelection.applicationTokens,
                categories: activitySelection.categoryTokens,
                webDomains: activitySelection.webDomainTokens,
                threshold: DateComponents(minute: minute)
            )
        }

        return events
    }
}
