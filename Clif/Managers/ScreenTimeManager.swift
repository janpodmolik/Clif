import Foundation
import Combine
import FamilyControls
import DeviceActivity
import ManagedSettings

extension DeviceActivityName {
    /// Creates a pet-specific activity name.
    static func forPet(_ petId: UUID) -> DeviceActivityName {
        DeviceActivityName("pet_\(petId.uuidString)")
    }
}

/// Manages Screen Time authorization and per-pet device activity monitoring.
/// Each pet can have its own set of monitored apps/categories with independent schedules.
final class ScreenTimeManager: ObservableObject {
    static let shared = ScreenTimeManager()

    @Published var isAuthorized = false

    /// Debug-only: Global activity selection for testing in DebugView.
    /// Production code should use pet.limitedSources instead.
    @Published var activitySelection = FamilyActivitySelection()

    private let center = DeviceActivityCenter()
    private let store = ManagedSettingsStore()

    private init() {
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

    // MARK: - Shield Management

    /// Activates shield for specific tokens.
    func activateShield(
        applications: Set<ApplicationToken>,
        categories: Set<ActivityCategoryToken>,
        webDomains: Set<WebDomainToken>
    ) {
        if !applications.isEmpty {
            store.shield.applications = applications
        }
        if !categories.isEmpty {
            store.shield.applicationCategories = .specific(categories, except: Set())
        }
        if !webDomains.isEmpty {
            store.shield.webDomains = webDomains
        }
    }

    func clearShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
    }

    // MARK: - Per-Pet Monitoring

    /// Starts monitoring for a specific pet using its limitedSources.
    /// - Parameters:
    ///   - petId: UUID of the pet being monitored
    ///   - mode: Pet mode (daily or dynamic)
    ///   - limitMinutes: Screen time limit in minutes
    ///   - windPoints: Current wind points for snapshot logging
    ///   - limitedSources: Pet's limited sources containing tokens to monitor
    func startMonitoring(
        petId: UUID,
        mode: PetMode,
        limitMinutes: Int,
        windPoints: Double,
        limitedSources: [LimitedSource]
    ) {
        let appTokens = limitedSources.applicationTokens
        let catTokens = limitedSources.categoryTokens
        let webTokens = limitedSources.webDomainTokens

        guard !appTokens.isEmpty || !catTokens.isEmpty || !webTokens.isEmpty else {
            #if DEBUG
            print("[ScreenTimeManager] No tokens to monitor for pet \(petId)")
            #endif
            return
        }

        // Save tokens for this pet (extension will load them)
        SharedDefaults.saveTokens(
            petId: petId,
            applications: appTokens,
            categories: catTokens,
            webDomains: webTokens
        )

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

        let events = buildEvents(
            for: mode,
            limitSeconds: limitMinutes * 60,
            appTokens: appTokens,
            catTokens: catTokens,
            webTokens: webTokens
        )

        let activityName = DeviceActivityName.forPet(petId)

        do {
            // Stop any existing monitoring for this pet before starting new
            center.stopMonitoring([activityName])
            try center.startMonitoring(activityName, during: schedule, events: events)
            #if DEBUG
            print("[ScreenTimeManager] Started \(mode.rawValue) monitoring with \(events.count) events for pet \(petId)")
            #endif
        } catch {
            #if DEBUG
            print("[ScreenTimeManager] Failed to start monitoring for pet \(petId): \(error.localizedDescription)")
            #endif
        }
    }

    /// Stops monitoring for a specific pet.
    func stopMonitoring(petId: UUID) {
        let activityName = DeviceActivityName.forPet(petId)
        center.stopMonitoring([activityName])

        // Clear tokens for this pet
        SharedDefaults.clearTokens(petId: petId)

        // Clear monitoring context if this was the active pet
        if SharedDefaults.monitoredPetId == petId {
            SharedDefaults.monitoredPetId = nil
            SharedDefaults.monitoredPetMode = nil
        }

        #if DEBUG
        print("[ScreenTimeManager] Stopped monitoring for pet \(petId)")
        #endif
    }

    /// Stops all monitoring.
    func stopAllMonitoring() {
        center.stopMonitoring()
        SharedDefaults.monitoredPetId = nil
        SharedDefaults.monitoredPetMode = nil
        #if DEBUG
        print("[ScreenTimeManager] Stopped all monitoring")
        #endif
    }

    // MARK: - Event Building

    private func buildEvents(
        for mode: PetMode,
        limitSeconds: Int,
        appTokens: Set<ApplicationToken>,
        catTokens: Set<ActivityCategoryToken>,
        webTokens: Set<WebDomainToken>
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        switch mode {
        case .daily:
            return buildDailyEvents(
                limitSeconds: limitSeconds,
                appTokens: appTokens,
                catTokens: catTokens,
                webTokens: webTokens
            )
        case .dynamic:
            return buildDynamicEvents(
                limitSeconds: limitSeconds,
                appTokens: appTokens,
                catTokens: catTokens,
                webTokens: webTokens
            )
        }
    }

    /// Daily mode: percentage thresholds + "1 minute before limit"
    private func buildDailyEvents(
        limitSeconds: Int,
        appTokens: Set<ApplicationToken>,
        catTokens: Set<ActivityCategoryToken>,
        webTokens: Set<WebDomainToken>
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        for percentage in AppConstants.dailyThresholdPercentages {
            let thresholdSeconds = max(AppConstants.minimumThresholdSeconds, (limitSeconds * percentage) / 100)
            let eventName = DeviceActivityEvent.Name("threshold_\(percentage)")

            events[eventName] = DeviceActivityEvent(
                applications: appTokens,
                categories: catTokens,
                webDomains: webTokens,
                threshold: DateComponents(minute: thresholdSeconds / 60, second: thresholdSeconds % 60)
            )
        }

        // "1 minute remaining" event
        let oneMinuteBeforeLimitSeconds = max(0, limitSeconds - 60)
        if oneMinuteBeforeLimitSeconds > 0 {
            events[DeviceActivityEvent.Name("lastMinute")] = DeviceActivityEvent(
                applications: appTokens,
                categories: catTokens,
                webDomains: webTokens,
                threshold: DateComponents(minute: oneMinuteBeforeLimitSeconds / 60, second: oneMinuteBeforeLimitSeconds % 60)
            )
        }

        return events
    }

    /// Dynamic mode: per-minute thresholds for granular windPoints tracking
    private func buildDynamicEvents(
        limitSeconds: Int,
        appTokens: Set<ApplicationToken>,
        catTokens: Set<ActivityCategoryToken>,
        webTokens: Set<WebDomainToken>
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        let limitMinutes = limitSeconds / 60

        // Create threshold for each minute (1, 2, 3, ..., limitMinutes)
        // Cap at maxDynamicThresholds due to DeviceActivity API limit
        let maxThresholds = min(limitMinutes, AppConstants.maxDynamicThresholds)

        for minute in 1...maxThresholds {
            let eventName = DeviceActivityEvent.Name("minute_\(minute)")

            events[eventName] = DeviceActivityEvent(
                applications: appTokens,
                categories: catTokens,
                webDomains: webTokens,
                threshold: DateComponents(minute: minute)
            )
        }

        return events
    }

    // MARK: - Debug Methods

    #if DEBUG
    /// Debug-only: Starts monitoring using the global activitySelection.
    /// Creates a temporary debug pet ID.
    func startMonitoring() {
        let debugPetId = UUID()
        let limitMinutes = SharedDefaults.dailyLimitMinutes

        startMonitoring(
            petId: debugPetId,
            mode: .daily,
            limitMinutes: limitMinutes,
            windPoints: 0,
            appTokens: activitySelection.applicationTokens,
            catTokens: activitySelection.categoryTokens,
            webTokens: activitySelection.webDomainTokens
        )
    }

    /// Debug-only: Applies shield using global activitySelection.
    func updateShield() {
        activateShield(
            applications: activitySelection.applicationTokens,
            categories: activitySelection.categoryTokens,
            webDomains: activitySelection.webDomainTokens
        )
    }

    /// Debug-only: Saves global selection (no-op for production).
    func saveSelection() {
        // For debug: just restart monitoring with current selection
        startMonitoring()
    }

    /// Internal helper for debug that takes tokens directly.
    private func startMonitoring(
        petId: UUID,
        mode: PetMode,
        limitMinutes: Int,
        windPoints: Double,
        appTokens: Set<ApplicationToken>,
        catTokens: Set<ActivityCategoryToken>,
        webTokens: Set<WebDomainToken>
    ) {
        guard !appTokens.isEmpty || !catTokens.isEmpty || !webTokens.isEmpty else {
            #if DEBUG
            print("[ScreenTimeManager] No tokens to monitor for pet \(petId)")
            #endif
            return
        }

        // Save tokens for this pet (extension will load them)
        SharedDefaults.saveTokens(
            petId: petId,
            applications: appTokens,
            categories: catTokens,
            webDomains: webTokens
        )

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

        let events = buildEvents(
            for: mode,
            limitSeconds: limitMinutes * 60,
            appTokens: appTokens,
            catTokens: catTokens,
            webTokens: webTokens
        )

        let activityName = DeviceActivityName.forPet(petId)

        do {
            center.stopMonitoring([activityName])
            try center.startMonitoring(activityName, during: schedule, events: events)
            print("[ScreenTimeManager] Started \(mode.rawValue) monitoring with \(events.count) events for pet \(petId)")
        } catch {
            print("[ScreenTimeManager] Failed to start monitoring for pet \(petId): \(error.localizedDescription)")
        }
    }
    #endif
}
