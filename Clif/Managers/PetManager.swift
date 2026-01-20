import Foundation

@Observable
final class PetManager {
    // MARK: - Private Storage

    private var pets: [ActivePet] = []

    // MARK: - Public API

    /// All active pets, sorted by creation date (newest first).
    var activePets: [ActivePet] {
        pets.sorted { $0.createdAt > $1.createdAt }
    }

    /// Currently selected pet for display (first in list).
    var currentPet: ActivePet? {
        activePets.first
    }

    // MARK: - Init

    init() {
        loadActivePets()

        #if DEBUG
        if pets.isEmpty {
            pets = [.daily(DailyPet.mockBlob(name: "Blob", canUseEssence: true, todayUsedMinutes: 100, dailyLimitMinutes: 120))]
        }
        #endif
    }

    // MARK: - Create

    /// Creates a new Daily pet (starts as blob).
    @discardableResult
    func createDaily(name: String, purpose: String?, dailyLimitMinutes: Int) -> DailyPet {
        let pet = DailyPet(
            name: name,
            evolutionHistory: EvolutionHistory(),
            purpose: purpose,
            todayUsedMinutes: 0,
            dailyLimitMinutes: dailyLimitMinutes
        )
        pets.append(.daily(pet))
        saveActivePets()
        return pet
    }

    /// Creates a new Dynamic pet (starts as blob).
    @discardableResult
    func createDynamic(name: String, purpose: String?, config: DynamicModeConfig = .default) -> DynamicPet {
        let pet = DynamicPet(
            name: name,
            evolutionHistory: EvolutionHistory(),
            purpose: purpose,
            config: config
        )
        pets.append(.dynamic(pet))
        saveActivePets()
        return pet
    }

    // MARK: - Archive

    /// Archives an active pet using ArchivedPetManager.
    func archive(id: UUID, using archivedPetManager: ArchivedPetManager) {
        guard let index = pets.firstIndex(where: { $0.id == id }) else { return }
        let pet = pets.remove(at: index)
        archivedPetManager.archive(pet)
        saveActivePets()
    }

    /// Blows away a pet and archives it.
    func blowAway(id: UUID, using archivedPetManager: ArchivedPetManager) {
        guard let pet = pets.first(where: { $0.id == id }) else { return }
        pet.blowAway()
        archive(id: id, using: archivedPetManager)
    }

    // MARK: - Delete

    /// Removes an active pet without archiving.
    func delete(id: UUID) {
        pets.removeAll { $0.id == id }
        saveActivePets()
    }

    // MARK: - Save Trigger

    /// Call after mutating a pet to persist changes.
    func savePets() {
        saveActivePets()
    }
}

// MARK: - Persistence (Active → SharedDefaults)

private extension PetManager {
    func loadActivePets() {
        var loaded: [ActivePet] = []

        if let data = SharedDefaults.data(forKey: DefaultsKeys.activeDailyPets),
           let dtos = try? JSONDecoder().decode([DailyPetDTO].self, from: data) {
            loaded += dtos.map { .daily(DailyPet(from: $0)) }
        }

        if let data = SharedDefaults.data(forKey: DefaultsKeys.activeDynamicPets),
           let dtos = try? JSONDecoder().decode([DynamicPetDTO].self, from: data) {
            loaded += dtos.map { .dynamic(DynamicPet(from: $0)) }
        }

        pets = loaded
    }

    func saveActivePets() {
        var dailyPets: [DailyPet] = []
        var dynamicPets: [DynamicPet] = []

        for pet in pets {
            switch pet {
            case .daily(let daily): dailyPets.append(daily)
            case .dynamic(let dynamic): dynamicPets.append(dynamic)
            }
        }

        let dailyDTOs = dailyPets.map { DailyPetDTO(from: $0) }
        if let data = try? JSONEncoder().encode(dailyDTOs) {
            SharedDefaults.setData(data, forKey: DefaultsKeys.activeDailyPets)
        }

        let dynamicDTOs = dynamicPets.map { DynamicPetDTO(from: $0) }
        if let data = try? JSONEncoder().encode(dynamicDTOs) {
            SharedDefaults.setData(data, forKey: DefaultsKeys.activeDynamicPets)
        }
    }
}

// MARK: - Mock Data

extension PetManager {
    static func mock(
        withDailyPets: Bool = true,
        withDynamicPets: Bool = false
    ) -> PetManager {
        let manager = PetManager()
        var mockPets: [ActivePet] = []
        if withDailyPets {
            mockPets += DailyPet.mockList().map { .daily($0) }
        }
        if withDynamicPets {
            mockPets += [DynamicPet.mock(), .mockWithBreak()].map { .dynamic($0) }
        }
        manager.pets = mockPets
        return manager
    }
}

import SwiftUI

#Preview {
    ContentView()
        .environment(PetManager.mock())
        .environment(ArchivedPetManager.mock())
}
