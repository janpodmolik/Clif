import Foundation

@Observable
final class PetManager {
    // MARK: - Private Storage

    private var pet: Pet?

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

    /// Archives the active pet using ArchivedPetManager.
    func archive(id: UUID, using archivedPetManager: ArchivedPetManager) {
        guard let currentPet = pet, currentPet.id == id else { return }

        // Stop monitoring before archiving
        ScreenTimeManager.shared.stopMonitoring(petId: id)

        archivedPetManager.archive(currentPet)
        pet = nil
        saveActivePet()
    }

    /// Blows away the pet and archives it.
    func blowAway(id: UUID, using archivedPetManager: ArchivedPetManager) {
        guard let currentPet = pet, currentPet.id == id else { return }
        currentPet.blowAway()
        archive(id: id, using: archivedPetManager)
    }

    // MARK: - Delete

    /// Removes the active pet without archiving.
    func delete(id: UUID) {
        guard let currentPet = pet, currentPet.id == id else { return }

        // Stop monitoring before deleting
        ScreenTimeManager.shared.stopMonitoring(petId: id)

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
        pet?.checkBlowAwayState()
    }

    // MARK: - Monitoring Restore

    /// Restores monitoring for existing pet after app restart/rebuild.
    /// DeviceActivityCenter schedules don't persist across app terminations,
    /// so we must re-register monitoring when the app launches.
    ///
    /// Uses SharedDefaults values directly (not pet properties) because SharedDefaults
    /// is the source of truth - extensions update it in real-time.
    private func restoreMonitoringIfNeeded() {
        guard let pet = pet,
              !pet.isBlownAway,
              !pet.limitedSources.isEmpty,
              SharedDefaults.monitoredPetId == pet.id else {
            return
        }

        // Read directly from SharedDefaults - this is the source of truth
        let windPoints = SharedDefaults.monitoredWindPoints
        let lastThresholdSeconds = SharedDefaults.monitoredLastThresholdSeconds

        ScreenTimeManager.shared.startMonitoring(
            petId: pet.id,
            limitSeconds: Int(pet.preset.minutesToBlowAway * 60),
            windPoints: windPoints,
            riseRatePerSecond: pet.preset.riseRate / 60.0,
            fallRatePerSecond: pet.preset.fallRate / 60.0,
            lastThresholdSeconds: lastThresholdSeconds,
            limitedSources: pet.limitedSources
        )
    }

    // MARK: - Daily Reset

    /// Performs daily reset if needed (new day since last activity).
    /// Call this on app launch and foreground return.
    func performDailyResetIfNeeded() {
        guard let pet = pet, !pet.isBlownAway else { return }

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
