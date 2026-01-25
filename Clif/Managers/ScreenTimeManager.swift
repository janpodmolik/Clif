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
            let existingActivities = center.activities
            if !existingActivities.isEmpty {
                center.stopMonitoring(existingActivities)
            }

            try center.startMonitoring(activityName, during: schedule, events: events)

            #if DEBUG
            print("[ScreenTimeManager] restartMonitoringAfterBreak: SUCCESS - \(events.count) events")
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
    /// - Restarts monitoring with fresh thresholds
    func processUnlock() {
        #if DEBUG
        print("[ScreenTimeManager] processUnlock() called")
        print("  Before: wind=\(SharedDefaults.monitoredWindPoints), lastThreshold=\(SharedDefaults.monitoredLastThresholdSeconds)")
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

        #if DEBUG
        print("  After break reduction: wind=\(SharedDefaults.monitoredWindPoints)")
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

        let limitSeconds = SharedDefaults.integer(forKey: DefaultsKeys.monitoringLimitSeconds)

        #if DEBUG
        print("[ScreenTimeManager] processUnlock: Restarting monitoring")
        print("  petId=\(petId), limit=\(limitSeconds)s")
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
            let existingActivities = center.activities
            if !existingActivities.isEmpty {
                center.stopMonitoring(existingActivities)
            }

            try center.startMonitoring(activityName, during: schedule, events: events)

            #if DEBUG
            print("[ScreenTimeManager] processUnlock: SUCCESS - \(events.count) events")
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
        let fallRatePerSecond = preset.fallRate / 60.0

        // Update SharedDefaults for extension
        SharedDefaults.monitoredFallRate = fallRatePerSecond
        SharedDefaults.setInt(limitSeconds, forKey: DefaultsKeys.monitoringLimitSeconds)

        // Reset wind state for new preset
        SharedDefaults.resetWindState()

        // Restart monitoring with new preset
        startMonitoring(
            petId: pet.id,
            limitSeconds: limitSeconds,
            limitedSources: pet.limitedSources
        )
    }

    // MARK: - Per-Pet Monitoring

    /// Starts monitoring for a specific pet using its limitedSources.
    /// Calculates remaining seconds based on current usage and break reduction.
    ///
    /// - Parameters:
    ///   - petId: UUID of the pet being monitored
    ///   - limitSeconds: Screen time limit in seconds (minutesToBlowAway * 60 from preset)
    ///   - limitedSources: Pet's limited sources containing tokens to monitor
    func startMonitoring(
        petId: UUID,
        limitSeconds: Int,
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
        SharedDefaults.setInt(limitSeconds, forKey: DefaultsKeys.monitoringLimitSeconds)

        // Reset all shield flags - fresh monitoring start means no shield blocking wind
        SharedDefaults.resetShieldFlags()

        #if DEBUG
        print("[ScreenTimeManager] startMonitoring:")
        print("  petId: \(petId)")
        print("  limitSeconds: \(limitSeconds)s")
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
            if !existingActivities.isEmpty {
                center.stopMonitoring(existingActivities)
            }

            try center.startMonitoring(activityName, during: schedule, events: events)

            #if DEBUG
            print("[ScreenTimeManager] Started monitoring: \(events.count) events")
            #endif
        } catch {
            #if DEBUG
            print("[ScreenTimeManager] Failed to start monitoring: \(error.localizedDescription)")
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

    /// Builds threshold events for monitoring.
    ///
    /// Always generates thresholds from 0s to limit+buffer.
    /// iOS automatically ignores thresholds that have already been passed.
    ///
    /// - Parameters:
    ///   - limitSeconds: Total screen time limit in seconds
    ///   - appTokens: Application tokens to monitor
    ///   - catTokens: Category tokens to monitor
    ///   - webTokens: Web domain tokens to monitor
    private func buildEvents(
        limitSeconds: Int,
        appTokens: Set<ApplicationToken>,
        catTokens: Set<ActivityCategoryToken>,
        webTokens: Set<WebDomainToken>
    ) -> [DeviceActivityEvent.Name: DeviceActivityEvent] {
        var events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]

        let maxThresholds = AppConstants.maxThresholds
        let minInterval = AppConstants.minimumThresholdSeconds

        // Add 10% buffer for blow-away detection (110%)
        let targetSeconds = limitSeconds + max(limitSeconds / 10, minInterval)

    // Calculate interval to spread thresholds evenly across full range
        let intervalSeconds = max(targetSeconds / maxThresholds, minInterval)

        #if DEBUG
        print("[ScreenTimeManager] buildEvents:")
        print("  limitSeconds: \(limitSeconds)s")
        print("  targetSeconds (with buffer): \(targetSeconds)s")
        print("  intervalSeconds: \(intervalSeconds)s")
        #endif

        // Generate thresholds from first interval to cover full range
        // iOS ignores already-passed thresholds automatically
        var currentSeconds = intervalSeconds

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
        print("  Created \(events.count) events")
        if let firstKey = events.keys.min(by: { $0.rawValue < $1.rawValue }) {
            print("  First threshold: \(firstKey.rawValue)")
        }
        if let lastKey = events.keys.max(by: { $0.rawValue < $1.rawValue }) {
            print("  Last threshold: \(lastKey.rawValue)")
        }
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
