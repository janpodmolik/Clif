import Foundation

@Observable
final class PetManager {
    private(set) var activePets: [ActivePet] = []
    private(set) var archivedPets: [ArchivedPet] = []

    /// Currently selected pet for display (first in carousel)
    var currentPet: ActivePet? {
        activePets.first
    }

    /// Archived pets that weren't blown (for Hall of Fame)
    var completedPets: [ArchivedPet] {
        archivedPets.filter { !$0.isBlown }
    }

    init() {
        loadArchivedPets()

        #if DEBUG
        // Add mock pet for development
        if activePets.isEmpty {
            activePets = [ActivePet.mockBlob(name: "Blob", canUseEssence: true, windLevel: .high)]
        }
        #endif
    }

    // MARK: - Active Pet Lifecycle

    /// Creates a new active pet (starts as blob)
    func createPet(name: String, purpose: String?, dailyLimitMinutes: Int) -> ActivePet {
        let pet = ActivePet(
            name: name,
            evolutionHistory: EvolutionHistory(),
            purpose: purpose,
            windLevel: .none,
            todayUsedMinutes: 0,
            dailyLimitMinutes: dailyLimitMinutes
        )
        activePets.append(pet)
        return pet
    }

    /// Archives an active pet (moves to archived list)
    func archive(_ pet: ActivePet) {
        guard let index = activePets.firstIndex(where: { $0.id == pet.id }) else { return }
        let archived = ArchivedPet(archiving: pet)
        archivedPets.insert(archived, at: 0)
        activePets.remove(at: index)
        saveArchivedPets()
    }

    /// Blows away a pet and archives it
    func blowAway(_ pet: ActivePet) {
        pet.blowAway()
        archive(pet)
    }

    /// Removes an active pet without archiving
    func delete(_ pet: ActivePet) {
        activePets.removeAll { $0.id == pet.id }
    }

    // MARK: - Archived Pet Management

    func deleteArchived(_ pet: ArchivedPet) {
        archivedPets.removeAll { $0.id == pet.id }
        saveArchivedPets()
    }

    // MARK: - Persistence (Archived only for now)

    private func loadArchivedPets() {
        guard let data = SharedDefaults.data(forKey: DefaultsKeys.archivedPets) else { return }
        archivedPets = (try? JSONDecoder().decode([ArchivedPet].self, from: data)) ?? []
    }

    private func saveArchivedPets() {
        let data = try? JSONEncoder().encode(archivedPets)
        SharedDefaults.setData(data, forKey: DefaultsKeys.archivedPets)
    }
}

// MARK: - Mock Data

extension PetManager {
    static func mock(withActivePets: Bool = true, withArchivedPets: Bool = true) -> PetManager {
        let manager = PetManager()
        if withActivePets {
            manager.activePets = ActivePet.mockList()
        }
        if withArchivedPets {
            manager.archivedPets = ArchivedPet.mockList()
        }
        return manager
    }
}

import SwiftUI

#Preview {
    ContentView()
        .environment(PetManager.mock(withActivePets: false))
}
