import Foundation

@Observable
final class PetManager {
    private(set) var activePets: [DailyPet] = []
    private(set) var archivedPets: [ArchivedDailyPet] = []

    /// Currently selected pet for display (first in carousel)
    var currentPet: DailyPet? {
        activePets.first
    }

    /// Archived pets that weren't blown (for Hall of Fame)
    var completedPets: [ArchivedDailyPet] {
        archivedPets.filter { !$0.isBlown }
    }

    init() {
        loadArchivedDailyPets()

        #if DEBUG
        // Add mock pet for development
        if activePets.isEmpty {
            activePets = [DailyPet.mockBlob(name: "Blob", canUseEssence: true, todayUsedMinutes: 100, dailyLimitMinutes: 120)]
        }
        #endif
    }

    // MARK: - Active Pet Lifecycle

    /// Creates a new active pet (starts as blob)
    func createPet(name: String, purpose: String?, dailyLimitMinutes: Int) -> DailyPet {
        let pet = DailyPet(
            name: name,
            evolutionHistory: EvolutionHistory(),
            purpose: purpose,
            todayUsedMinutes: 0,
            dailyLimitMinutes: dailyLimitMinutes
        )
        activePets.append(pet)
        return pet
    }

    /// Archives an active pet (moves to archived list)
    func archive(_ pet: DailyPet) {
        guard let index = activePets.firstIndex(where: { $0.id == pet.id }) else { return }
        let archived = ArchivedDailyPet(archiving: pet)
        archivedPets.insert(archived, at: 0)
        activePets.remove(at: index)
        saveArchivedDailyPets()
    }

    /// Blows away a pet and archives it
    func blowAway(_ pet: DailyPet) {
        pet.blowAway()
        archive(pet)
    }

    /// Removes an active pet without archiving
    func delete(_ pet: DailyPet) {
        activePets.removeAll { $0.id == pet.id }
    }

    // MARK: - Archived Pet Management

    func deleteArchived(_ pet: ArchivedDailyPet) {
        archivedPets.removeAll { $0.id == pet.id }
        saveArchivedDailyPets()
    }

    // MARK: - Persistence (Archived only for now)

    private func loadArchivedDailyPets() {
        guard let data = SharedDefaults.data(forKey: DefaultsKeys.archivedPets) else { return }
        archivedPets = (try? JSONDecoder().decode([ArchivedDailyPet].self, from: data)) ?? []
    }

    private func saveArchivedDailyPets() {
        let data = try? JSONEncoder().encode(archivedPets)
        SharedDefaults.setData(data, forKey: DefaultsKeys.archivedPets)
    }
}

// MARK: - Mock Data

extension PetManager {
    static func mock(withDailyPets: Bool = true, withArchivedDailyPets: Bool = true) -> PetManager {
        let manager = PetManager()
        if withDailyPets {
            manager.activePets = DailyPet.mockList()
        }
        if withArchivedDailyPets {
            manager.archivedPets = ArchivedDailyPet.mockList()
        }
        return manager
    }
}

import SwiftUI

#Preview {
    ContentView()
        .environment(PetManager.mock(withDailyPets: false))
}
