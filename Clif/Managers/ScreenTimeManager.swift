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
///
/// Shield-related operations are delegated to ShieldManager.
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

    // MARK: - Shield Delegation

    /// Activates shield for specific tokens.
    func activateShield(
        applications: Set<ApplicationToken>,
        categories: Set<ActivityCategoryToken>,
        webDomains: Set<WebDomainToken>
    ) {
        ShieldManager.shared.activate(applications: applications, categories: categories, webDomains: webDomains)
    }

    func clearShield() {
        ShieldManager.shared.clear()
    }

    func toggleShield() {
        ShieldManager.shared.toggle()
    }

    func processUnlock() {
        ShieldManager.shared.processUnlock()
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

        let events = MonitoringEventBuilder.buildEvents(
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
