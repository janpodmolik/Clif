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
        #if DEBUG
        print("DEBUG: clearShield() called")
        #endif
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        SharedDefaults.resetShieldFlags()
    }

    // MARK: - Morning Preset

    /// Applies the selected morning preset for today.
    /// - Saves preset selection to SharedDefaults
    /// - Clears any existing shields
    /// - Restarts monitoring with new preset parameters
    func applyMorningPreset(_ preset: WindPreset, for pet: Pet) {
        // Save selected preset
        SharedDefaults.todaySelectedPreset = preset.rawValue
        SharedDefaults.windPresetLockedForToday = true
        SharedDefaults.windPresetLockedDate = Date()

        // Clear shields and reset all shield flags
        clearShield()

        // Calculate monitoring parameters from preset
        let limitSeconds = Int(preset.minutesToBlowAway * 60)
        let riseRatePerSecond = preset.riseRate / 60.0

        // Update SharedDefaults for extension
        SharedDefaults.monitoredRiseRate = riseRatePerSecond
        SharedDefaults.setInt(limitSeconds, forKey: DefaultsKeys.monitoringLimitSeconds)

        // Restart monitoring with new preset
        startMonitoring(
            petId: pet.id,
            limitSeconds: limitSeconds,
            windPoints: 0,
            riseRatePerSecond: riseRatePerSecond,
            lastThresholdSeconds: 0,
            limitedSources: pet.limitedSources
        )
    }

    // MARK: - Per-Pet Monitoring

    /// Starts monitoring for a specific pet using its limitedSources.
    /// - Parameters:
    ///   - petId: UUID of the pet being monitored
    ///   - limitSeconds: Screen time limit in seconds (minutesToBlowAway * 60 from config)
    ///   - windPoints: Current wind points for snapshot logging
    ///   - riseRatePerSecond: Wind points per second of usage (from preset, divided by 60)
    ///   - lastThresholdSeconds: Last recorded threshold seconds (for resuming mid-day)
    ///   - limitedSources: Pet's limited sources containing tokens to monitor
    func startMonitoring(
        petId: UUID,
        limitSeconds: Int,
        windPoints: Double,
        riseRatePerSecond: Double,
        lastThresholdSeconds: Int = 0,
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

        // Update monitoring context for extensions (extension uses these to calculate wind)
        SharedDefaults.monitoredPetId = petId
        SharedDefaults.monitoredWindPoints = windPoints
        SharedDefaults.monitoredLastThresholdSeconds = lastThresholdSeconds
        SharedDefaults.monitoredRiseRate = riseRatePerSecond
        SharedDefaults.setInt(limitSeconds, forKey: DefaultsKeys.monitoringLimitSeconds)

        // Reset all shield flags - fresh monitoring start means no shield blocking wind
        #if DEBUG
        print("DEBUG: startMonitoring - about to resetShieldFlags()")
        #endif
        SharedDefaults.resetShieldFlags()
        #if DEBUG
        print("DEBUG: startMonitoring - after resetShieldFlags(), isShieldActive=\(SharedDefaults.isShieldActive), isMorningShieldActive=\(SharedDefaults.isMorningShieldActive)")
        #endif

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let events = buildEvents(
            limitSeconds: limitSeconds,
            appTokens: appTokens,
            catTokens: catTokens,
            webTokens: webTokens
        )

        let activityName = DeviceActivityName.forPet(petId)

        do {
            // Stop ALL existing monitoring before starting new (prevents excessiveActivities error)
            let existingActivities = center.activities
            #if DEBUG
            print("DEBUG: Existing activities count: \(existingActivities.count)")
            print("DEBUG: Existing activities: \(existingActivities.map { $0.rawValue })")
            #endif

            if !existingActivities.isEmpty {
                center.stopMonitoring(existingActivities)
                #if DEBUG
                print("DEBUG: Stopped all existing activities")
                #endif
            }

            #if DEBUG
            print("DEBUG: About to startMonitoring")
            print("DEBUG: Activity name: \(activityName.rawValue)")
            print("DEBUG: Schedule: \(schedule)")
            print("DEBUG: Events count: \(events.count)")
            print("DEBUG: First 3 event keys: \(Array(events.keys.prefix(3)).map { $0.rawValue })")
            print("DEBUG: App tokens count: \(appTokens.count)")
            print("DEBUG: Category tokens count: \(catTokens.count)")
            print("DEBUG: Web tokens count: \(webTokens.count)")
            #endif

            try center.startMonitoring(activityName, during: schedule, events: events)

            #if DEBUG
            print("DEBUG: startMonitoring SUCCESS")
            print("[ScreenTimeManager] Started monitoring with \(events.count) events, limit: \(limitSeconds)s for pet \(petId)")
            #endif
        } catch {
            #if DEBUG
            print("DEBUG: startMonitoring FAILED: \(error)")
            print("[ScreenTimeManager] Failed to start monitoring for pet \(petId): \(error.localizedDescription)")
            #endif
        }
    }

    /// Stops monitoring for a specific pet.
    func stopMonitoring(petId: UUID) {
        let activityName = DeviceActivityName.forPet(petId)
        center.stopMonitoring([activityName])

        // Clear any active shields (prevents stale shield showing after pet deletion)
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil

        // Clear tokens for this pet
        SharedDefaults.clearTokens(petId: petId)

        // Clear monitoring context and shield flags if this was the active pet
        if SharedDefaults.monitoredPetId == petId {
            SharedDefaults.monitoredPetId = nil
            SharedDefaults.resetShieldFlags()
        }

        #if DEBUG
        print("[ScreenTimeManager] Stopped monitoring for pet \(petId), shields cleared")
        #endif
    }

    /// Stops all monitoring.
    func stopAllMonitoring() {
        center.stopMonitoring()
        SharedDefaults.monitoredPetId = nil
        #if DEBUG
        print("[ScreenTimeManager] Stopped all monitoring")
        #endif
    }

    // MARK: - Event Building

    /// Builds thresholds for granular windPoints tracking.
    /// Generates thresholds up to 100% of the limit.
    private func buildEvents(
        limitSeconds: Int,
        appTokens: Set<ApplicationToken>,
        catTokens: Set<ActivityCategoryToken>,
        webTokens: Set<WebDomainToken>
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        let maxThresholds = AppConstants.maxThresholds
        let minInterval = AppConstants.minimumThresholdSeconds

        #if DEBUG
        print("DEBUG: buildEvents - limitSeconds=\(limitSeconds), maxThresholds=\(maxThresholds), minInterval=\(minInterval)")
        #endif

        // Calculate optimal interval to fit maxThresholds within limit
        // intervalSeconds = limitSeconds / maxThresholds, but at least minInterval
        let intervalSeconds = max(limitSeconds / maxThresholds, minInterval)

        #if DEBUG
        print("DEBUG: buildEvents - calculated intervalSeconds=\(intervalSeconds)")
        #endif

        // Generate thresholds: interval, 2*interval, 3*interval, ... up to limitSeconds
        var currentSeconds = intervalSeconds
        while currentSeconds <= limitSeconds && events.count < maxThresholds {
            let eventName = DeviceActivityEvent.Name("second_\(currentSeconds)")

            // DateComponents supports second precision
            let minutes = currentSeconds / 60
            let seconds = currentSeconds % 60

            events[eventName] = DeviceActivityEvent(
                applications: appTokens,
                categories: catTokens,
                webDomains: webTokens,
                threshold: DateComponents(minute: minutes, second: seconds)
            )

            currentSeconds += intervalSeconds
        }

        // Always include the limit threshold to ensure we hit exactly 100%
        if events.count < maxThresholds {
            let finalEventName = DeviceActivityEvent.Name("second_\(limitSeconds)")
            if events[finalEventName] == nil {
                let minutes = limitSeconds / 60
                let seconds = limitSeconds % 60
                events[finalEventName] = DeviceActivityEvent(
                    applications: appTokens,
                    categories: catTokens,
                    webDomains: webTokens,
                    threshold: DateComponents(minute: minutes, second: seconds)
                )
            }
        }

        #if DEBUG
        print("DEBUG: buildEvents - created \(events.count) events (up to \(limitSeconds)s)")
        print("[ScreenTimeManager] Built \(events.count) events with \(intervalSeconds)s interval for \(limitSeconds)s limit")
        #endif

        return events
    }

    // MARK: - Debug Methods

    #if DEBUG
    /// Debug-only: Applies shield using global activitySelection.
    func updateShield() {
        activateShield(
            applications: activitySelection.applicationTokens,
            categories: activitySelection.categoryTokens,
            webDomains: activitySelection.webDomainTokens
        )
    }
    #endif
}
