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

    // MARK: - Shield Toggle (from UI)

    /// Toggles shield on/off from the home screen button.
    /// When turning ON: activates shield for monitored tokens, records activation time.
    /// When turning OFF: calculates wind decrease, clears shield.
    func toggleShield() {
        if SharedDefaults.isShieldActive {
            // Shield is active -> turn OFF
            #if DEBUG
            print("[ScreenTimeManager] toggleShield: OFF")
            #endif

            applyBreakReduction()
            deactivateShield()

            // Start cooldown - shield won't auto-activate for 30 seconds
            // This allows wind to rise to 105%+ for blow-away if user continues using apps
            let cooldownSeconds: TimeInterval = 30
            SharedDefaults.shieldCooldownUntil = Date().addingTimeInterval(cooldownSeconds)
            #if DEBUG
            print("  Cooldown set for \(cooldownSeconds)s")
            #endif

            // IMPORTANT: Restart monitoring with new thresholds
            // After break, totalBreakReduction changed, so we need new thresholds
            // that cover the extended range needed to reach 105% wind
            restartMonitoringAfterBreak()
        } else {
            // Shield is off -> turn ON
            #if DEBUG
            print("[ScreenTimeManager] toggleShield: ON")
            #endif

            // Load tokens
            guard let appTokens = SharedDefaults.loadApplicationTokens(),
                  let catTokens = SharedDefaults.loadCategoryTokens() else {
                #if DEBUG
                print("  Failed to load tokens")
                #endif
                return
            }
            let webTokens = SharedDefaults.loadWebDomainTokens() ?? Set()

            // Activate shield
            activateShield(applications: appTokens, categories: catTokens, webDomains: webTokens)

            // Mark shield as active with timestamp
            SharedDefaults.isShieldActive = true
            SharedDefaults.shieldActivatedAt = Date()
            SharedDefaults.synchronize()

            #if DEBUG
            print("  Shield activated at \(Date())")
            #endif
        }
    }

    // MARK: - Shield Helpers

    /// Calculates break reduction based on shield duration, adds to totalBreakReduction,
    /// and immediately recalculates wind using WindCalculator.
    private func applyBreakReduction() {
        guard let activatedAt = SharedDefaults.shieldActivatedAt else { return }

        let elapsedSeconds = Int(Date().timeIntervalSince(activatedAt))
        let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
        let fallRate = SharedDefaults.monitoredFallRate

        // fallRate is in pts/sec, limit is 100 pts
        // secondsForgiven = elapsedSeconds * fallRate * limitSeconds / 100
        let secondsForgiven = Int(Double(elapsedSeconds) * fallRate * Double(limitSeconds) / 100.0)

        let oldReduction = SharedDefaults.totalBreakReduction
        let newReduction = oldReduction + secondsForgiven
        SharedDefaults.totalBreakReduction = newReduction

        // Recalculate wind using WindCalculator
        let oldWind = SharedDefaults.monitoredWindPoints
        let newWind = WindCalculator.currentWind()
        SharedDefaults.monitoredWindPoints = newWind

        #if DEBUG
        let cumulativeSeconds = SharedDefaults.monitoredLastThresholdSeconds
        let effectiveSeconds = max(0, cumulativeSeconds - newReduction)
        print("[ScreenTimeManager] Break reduction: +\(secondsForgiven)s (elapsed: \(elapsedSeconds)s, fallRate: \(fallRate), total: \(newReduction)s)")
        print("[ScreenTimeManager] Wind recalculated: \(String(format: "%.1f", oldWind)) -> \(String(format: "%.1f", newWind))% (cumulative: \(cumulativeSeconds)s, effective: \(effectiveSeconds)s)")
        #endif
    }

    /// Clears shield from ManagedSettingsStore and resets shield flags.
    private func deactivateShield() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        SharedDefaults.resetShieldFlags()
    }

    /// Restarts monitoring with new thresholds after break.
    /// Called after toggleShield OFF to regenerate thresholds that account for
    /// the updated totalBreakReduction value.
    private func restartMonitoringAfterBreak() {
        guard let petId = SharedDefaults.monitoredPetId else {
            #if DEBUG
            print("[ScreenTimeManager] restartMonitoringAfterBreak: No monitored pet")
            #endif
            return
        }

        guard let appTokens = SharedDefaults.loadApplicationTokens(),
              let catTokens = SharedDefaults.loadCategoryTokens() else {
            #if DEBUG
            print("[ScreenTimeManager] restartMonitoringAfterBreak: Failed to load tokens")
            #endif
            return
        }

        let webTokens = SharedDefaults.loadWebDomainTokens() ?? Set()

        guard !appTokens.isEmpty || !catTokens.isEmpty else {
            #if DEBUG
            print("[ScreenTimeManager] restartMonitoringAfterBreak: No tokens to monitor")
            #endif
            return
        }

        let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)
        let currentUsageSeconds = SharedDefaults.monitoredLastThresholdSeconds

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        let events = buildEventsFromPosition(
            startFromSeconds: currentUsageSeconds,
            limitSeconds: limitSeconds,
            appTokens: appTokens,
            catTokens: catTokens,
            webTokens: webTokens
        )

        let activityName = DeviceActivityName.forPet(petId)

        do {
            let existingActivities = center.activities
            if !existingActivities.isEmpty {
                center.stopMonitoring(existingActivities)
            }

            try center.startMonitoring(activityName, during: schedule, events: events)

            #if DEBUG
            print("[ScreenTimeManager] restartMonitoringAfterBreak: SUCCESS - \(events.count) events from \(currentUsageSeconds)s")
            #endif
        } catch {
            #if DEBUG
            print("[ScreenTimeManager] restartMonitoringAfterBreak: FAILED - \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Unlock Processing

    /// Processes unlock request from shield deep link.
    /// Called when user taps unlock notification from ShieldAction.
    /// - Calculates wind decrease from shield time
    /// - Clears shields
    /// - Restarts monitoring with fresh thresholds from 0
    func processUnlock() {
        #if DEBUG
        print("[ScreenTimeManager] processUnlock() called")
        print("  Before: wind=\(SharedDefaults.monitoredWindPoints), lastThreshold=\(SharedDefaults.monitoredLastThresholdSeconds)")
        print("  cooldownUntil=\(String(describing: SharedDefaults.shieldCooldownUntil)), isOnCooldown=\(SharedDefaults.isShieldOnCooldown)")
        #endif

        guard let petId = SharedDefaults.monitoredPetId else {
            #if DEBUG
            print("[ScreenTimeManager] processUnlock: No monitored pet, just clearing shields")
            #endif
            clearShield()
            return
        }

        // Calculate break reduction and clear shield
        applyBreakReduction()
        deactivateShield()

        // Note: Cooldown is already set by ShieldActionExtension.handleUnlockRequest()
        // This ensures cooldown is active even before user taps the notification
        #if DEBUG
        print("  After break reduction: wind=\(SharedDefaults.monitoredWindPoints), cooldown=\(SharedDefaults.isShieldOnCooldown)")
        #endif

        // Load tokens for restart
        guard let appTokens = SharedDefaults.loadApplicationTokens(),
              let catTokens = SharedDefaults.loadCategoryTokens() else {
            #if DEBUG
            print("[ScreenTimeManager] processUnlock: Failed to load tokens, cannot restart monitoring")
            #endif
            return
        }

        let webTokens = SharedDefaults.loadWebDomainTokens() ?? Set()

        guard !appTokens.isEmpty || !catTokens.isEmpty else {
            #if DEBUG
            print("[ScreenTimeManager] processUnlock: No tokens to monitor")
            #endif
            return
        }

        // Get limit from SharedDefaults
        let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)

        // Get current cumulative usage (this is the key!)
        // Thresholds must start from current position, not from 0
        let currentUsageSeconds = SharedDefaults.monitoredLastThresholdSeconds

        #if DEBUG
        let windPoints = SharedDefaults.monitoredWindPoints
        print("[ScreenTimeManager] processUnlock: Restarting monitoring from \(currentUsageSeconds)s")
        print("  petId=\(petId), limit=\(limitSeconds)s, wind=\(windPoints)")
        #endif

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )

        // Build events starting from current usage position
        let events = buildEventsFromPosition(
            startFromSeconds: currentUsageSeconds,
            limitSeconds: limitSeconds,
            appTokens: appTokens,
            catTokens: catTokens,
            webTokens: webTokens
        )

        let activityName = DeviceActivityName.forPet(petId)

        do {
            // Stop existing monitoring
            let existingActivities = center.activities
            if !existingActivities.isEmpty {
                center.stopMonitoring(existingActivities)
                #if DEBUG
                print("[ScreenTimeManager] processUnlock: Stopped \(existingActivities.count) existing activities")
                #endif
            }

            // Start fresh monitoring
            try center.startMonitoring(activityName, during: schedule, events: events)

            #if DEBUG
            print("[ScreenTimeManager] processUnlock: SUCCESS - monitoring restarted with \(events.count) events")
            #endif
        } catch {
            #if DEBUG
            print("[ScreenTimeManager] processUnlock: FAILED - \(error.localizedDescription)")
            #endif
        }
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
        let fallRatePerSecond = preset.fallRate / 60.0

        // Update SharedDefaults for extension
        SharedDefaults.monitoredRiseRate = riseRatePerSecond
        SharedDefaults.monitoredFallRate = fallRatePerSecond
        SharedDefaults.setInt(limitSeconds, forKey: DefaultsKeys.monitoringLimitSeconds)

        // Restart monitoring with new preset
        startMonitoring(
            petId: pet.id,
            limitSeconds: limitSeconds,
            windPoints: 0,
            riseRatePerSecond: riseRatePerSecond,
            fallRatePerSecond: fallRatePerSecond,
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
    ///   - fallRatePerSecond: Wind points per second of recovery (from preset, divided by 60)
    ///   - lastThresholdSeconds: Last recorded threshold seconds (for resuming mid-day)
    ///   - limitedSources: Pet's limited sources containing tokens to monitor
    func startMonitoring(
        petId: UUID,
        limitSeconds: Int,
        windPoints: Double,
        riseRatePerSecond: Double,
        fallRatePerSecond: Double,
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
        SharedDefaults.monitoredFallRate = fallRatePerSecond
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

    /// Builds thresholds starting from a specific position.
    /// Used after unlock to generate fresh thresholds from current usage.
    /// Target is dynamically calculated based on totalBreakReduction.
    private func buildEventsFromPosition(
        startFromSeconds: Int,
        limitSeconds: Int,
        appTokens: Set<ApplicationToken>,
        catTokens: Set<ActivityCategoryToken>,
        webTokens: Set<WebDomainToken>
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        let maxThresholds = AppConstants.maxThresholds
        let minInterval = AppConstants.minimumThresholdSeconds

        // Dynamic target: cumulative seconds needed for 100% wind
        // wind = (cumulative - breakReduction) / limit * 100 = 100
        // => cumulative = breakReduction + limit
        let breakReduction = SharedDefaults.totalBreakReduction
        let targetSeconds = breakReduction + limitSeconds

        // Buffer 10% for safety margin
        let targetWithBuffer = targetSeconds + max(limitSeconds / 10, minInterval)

        let remainingSeconds = max(targetWithBuffer - startFromSeconds, minInterval * maxThresholds)
        let intervalSeconds = max(remainingSeconds / maxThresholds, minInterval)

        #if DEBUG
        print("DEBUG: buildEventsFromPosition - startFrom=\(startFromSeconds)s, limit=\(limitSeconds)s, breakReduction=\(breakReduction)s, target=\(targetWithBuffer)s, interval=\(intervalSeconds)s")
        #endif

        // Generate thresholds starting from next interval after current position
        var currentSeconds = ((startFromSeconds / intervalSeconds) + 1) * intervalSeconds

        while events.count < maxThresholds {
            let eventName = DeviceActivityEvent.Name("second_\(currentSeconds)")
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

        #if DEBUG
        print("DEBUG: buildEventsFromPosition - created \(events.count) events starting from \(startFromSeconds)s")
        #endif

        return events
    }

    /// Builds thresholds for granular windPoints tracking.
    /// Target is dynamically calculated based on totalBreakReduction.
    private func buildEvents(
        limitSeconds: Int,
        appTokens: Set<ApplicationToken>,
        catTokens: Set<ActivityCategoryToken>,
        webTokens: Set<WebDomainToken>
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        let maxThresholds = AppConstants.maxThresholds
        let minInterval = AppConstants.minimumThresholdSeconds

        // Dynamic target: cumulative seconds needed for 100% wind
        // wind = (cumulative - breakReduction) / limit * 100 = 100
        // => cumulative = breakReduction + limit
        let breakReduction = SharedDefaults.totalBreakReduction
        let targetSeconds = breakReduction + limitSeconds

        // Buffer 10% for safety margin
        let targetWithBuffer = targetSeconds + max(limitSeconds / 10, minInterval)

        #if DEBUG
        print("DEBUG: buildEvents - limitSeconds=\(limitSeconds), breakReduction=\(breakReduction)s, target=\(targetWithBuffer)s, maxThresholds=\(maxThresholds)")
        #endif

        // Calculate optimal interval to fit maxThresholds within target
        let intervalSeconds = max(targetWithBuffer / maxThresholds, minInterval)

        #if DEBUG
        print("DEBUG: buildEvents - calculated intervalSeconds=\(intervalSeconds)")
        #endif

        // Generate thresholds: interval, 2*interval, 3*interval, ... up to target
        var currentSeconds = intervalSeconds
        while currentSeconds <= targetWithBuffer && events.count < maxThresholds {
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

        #if DEBUG
        print("DEBUG: buildEvents - created \(events.count) events (up to \(targetWithBuffer)s)")
        print("[ScreenTimeManager] Built \(events.count) events with \(intervalSeconds)s interval for target \(targetWithBuffer)s (limit: \(limitSeconds)s, breakReduction: \(breakReduction)s)")
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
