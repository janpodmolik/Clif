import FamilyControls
import Foundation

@Observable
final class PetManager {
    // MARK: - Constants

    /// Pets younger than this are deleted instead of archived (not enough data to be useful).
    static let minimumArchiveDays = 3

    // MARK: - Private Storage

    private var pet: Pet?

    /// Whether a re-authorization prompt is pending (prevents spam on repeated .active cycles).
    var needsReauthorization = false

    // MARK: - Public API

    /// Whether a pet currently exists (max one allowed).
    var hasPet: Bool { pet != nil }

    /// The current active pet (max one).
    var currentPet: Pet? { pet }

    // MARK: - Init

    init() {
        loadActivePet()
        restoreMonitoringIfNeeded()
    }

    // MARK: - Create

    /// Creates a new pet (starts as blob). Returns nil if a pet already exists.
    @discardableResult
    func create(
        name: String,
        purpose: String?,
        preset: WindPreset = .default,
        limitedSources: [LimitedSource] = []
    ) -> Pet? {
        guard pet == nil else { return nil }

        let newPet = Pet(
            name: name,
            evolutionHistory: EvolutionHistory(),
            purpose: purpose,
            preset: preset,
            limitedSources: limitedSources
        )
        pet = newPet
        saveActivePet()
        return newPet
    }

    // MARK: - Archive

    /// Archives the active pet, or deletes it if too young to be worth keeping.
    func archive(id: UUID, using archivedPetManager: ArchivedPetManager) {
        guard let currentPet = pet, currentPet.id == id else { return }

        // Stop monitoring and clear all data
        ScreenTimeManager.shared.stopMonitoringAndClear()

        // Pets younger than minimum days are just deleted (not enough data to archive)
        guard currentPet.daysSinceCreation >= Self.minimumArchiveDays else {
            pet = nil
            saveActivePet()
            return
        }

        let reason: ArchiveReason = currentPet.isBlown ? .blown
            : currentPet.isFullyEvolved ? .completed
            : .manual

        archivedPetManager.archive(currentPet, reason: reason)
        pet = nil
        saveActivePet()
    }

    /// Blows away the pet and archives it.
    func blowAway(id: UUID, using archivedPetManager: ArchivedPetManager) {
        guard let currentPet = pet, currentPet.id == id else { return }
        currentPet.blowAway()
        archive(id: id, using: archivedPetManager)
    }

    // MARK: - Authorization Check

    /// Checks if FamilyControls authorization was lost and signals the UI to show re-authorization prompt.
    /// Does NOT archive immediately — gives the user a chance to re-authorize.
    /// Call on app activation (foreground return).
    func checkAuthorizationStatus() {
        guard let pet, !pet.isBlownAway, !needsReauthorization else { return }

        let isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
        if !isAuthorized {
            needsReauthorization = true
        }
    }

    /// Call after the user successfully re-authorizes to resume normal operation.
    func handleReauthorizationSuccess() {
        needsReauthorization = false
        restoreMonitoringIfNeeded()
    }

    /// Call when the user declines re-authorization — marks the pet as blown away.
    /// Does NOT archive — the user sees the blow-away animation and archives manually.
    func handleReauthorizationDeclined() {
        needsReauthorization = false
        blowAwayCurrentPet(reason: .limitExceeded)
    }

    /// Marks the current pet as blown away (e.g. when violating a committed break).
    func blowAwayCurrentPet(reason: BlowAwayReason = .limitExceeded) {
        guard let pet = pet, !pet.isBlown else { return }

        // Cancel any active break/shield and stop monitoring
        ShieldManager.shared.clear()
        ScreenTimeManager.shared.stopMonitoring()

        // Set wind to 100% so blown away state looks correct visually
        SharedDefaults.monitoredWindPoints = 100

        pet.blowAway(reason: reason)
        saveActivePet()
    }

    // MARK: - Delete

    /// Removes the active pet without archiving.
    func delete(id: UUID) {
        guard let currentPet = pet, currentPet.id == id else { return }

        // Stop monitoring and clear all data before deleting
        ScreenTimeManager.shared.stopMonitoringAndClear()

        pet = nil
        saveActivePet()
    }

    // MARK: - Save Trigger

    /// Call after mutating the pet to persist changes.
    func savePet() {
        saveActivePet()
    }

    // MARK: - Foreground Sync

    /// Checks for blow-away state when app returns to foreground.
    /// windPoints is computed from SharedDefaults, so no sync needed.
    func checkBlowAwayState() {
        let wasBlown = pet?.isBlown ?? false
        pet?.checkBlowAwayState()
        if pet?.isBlown == true && !wasBlown {
            saveActivePet()
        }
    }

    /// Refreshes daily usage stats from snapshots.
    /// Call on foreground return to populate usage history.
    func refreshDailyStats() {
        guard let pet = pet else { return }
        pet.dailyStats = SnapshotStore.shared.dailyUsageStats(petId: pet.id)
    }

    // MARK: - Monitoring Restore

    /// Restores monitoring for existing pet after app restart/rebuild.
    /// DeviceActivityCenter schedules don't persist across app terminations,
    /// so we must re-register monitoring when the app launches.
    ///
    /// Skips restore when a break is active — monitoring is intentionally paused
    /// during breaks and will be restored by ShieldManager.turnOff via restartMonitoring.
    private func restoreMonitoringIfNeeded() {
        guard let pet = pet,
              !pet.isBlownAway,
              !pet.limitedSources.isEmpty,
              SharedDefaults.monitoredPetId == pet.id,
              !SharedDefaults.isShieldActive else {
            return
        }

        let limitSeconds = Int(pet.preset.minutesToBlowAway * 60)

        ScreenTimeManager.shared.startMonitoring(
            petId: pet.id,
            limitSeconds: limitSeconds,
            limitedSources: pet.limitedSources
        )
    }

    // MARK: - Daily Reset

    /// Performs daily reset if needed (new day since last activity).
    /// Call this on app launch and foreground return.
    func performDailyResetIfNeeded() {
        guard let pet = pet, pet.windPoints.isZero, !pet.isBlownAway else { return }

        let today = SnapshotEvent.dateString(from: Date())
        let lastResetKey = "lastDailyReset_\(pet.id.uuidString)"

        if let lastReset = UserDefaults.standard.string(forKey: lastResetKey),
           lastReset == today {
            // Already reset today
            return
        }

        // Check if we have any usage from today - if not, don't reset yet
        // (user might be opening app for first time today)
        let todaySnapshots = SnapshotStore.shared.load(for: today)
        let hasSystemDayStart = todaySnapshots.contains { $0.eventType == .systemDayStart }

        if hasSystemDayStart {
            // New monitoring interval started, reset wind
            pet.resetWind()
            SnapshotLogging.logDailyReset(petId: pet.id, windPoints: 0)
            UserDefaults.standard.set(today, forKey: lastResetKey)
            saveActivePet()

            #if DEBUG
            print("[PetManager] Daily reset performed for pet \(pet.id)")
            #endif
        }
    }
}

// MARK: - Persistence (Active → SharedDefaults)

private extension PetManager {
    /// Loads the active pet from storage.
    func loadActivePet() {
        guard let data = SharedDefaults.data(forKey: DefaultsKeys.activePet),
              let dto = try? JSONDecoder().decode(PetDTO.self, from: data) else {
            return
        }
        pet = Pet(from: dto)
    }

    /// Saves the active pet to SharedDefaults.
    func saveActivePet() {
        if let pet = pet,
           let data = try? JSONEncoder().encode(PetDTO(from: pet)) {
            SharedDefaults.setData(data, forKey: DefaultsKeys.activePet)
        } else {
            SharedDefaults.removeObject(forKey: DefaultsKeys.activePet)
        }
    }
}

// MARK: - Mock Data

extension PetManager {
    static func mock(withPet: Bool = true) -> PetManager {
        let manager = PetManager()
        if withPet {
            manager.pet = Pet.mock()
        }
        return manager
    }
}

import SwiftUI

#Preview {
    ContentView()
        .environment(PetManager.mock())
        .environment(ArchivedPetManager.mock())
}
