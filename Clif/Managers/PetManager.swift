import Foundation

@Observable
final class PetManager {
    // MARK: - Private Storage

    private var pets: [Pet] = []

    // MARK: - Public API

    /// All active pets, sorted by creation date (newest first).
    var activePets: [Pet] {
        pets.sorted { $0.evolutionHistory.createdAt > $1.evolutionHistory.createdAt }
    }

    /// Currently selected pet for display (first in list).
    var currentPet: Pet? {
        activePets.first
    }

    // MARK: - Init

    init() {
        loadActivePets()

        #if DEBUG
        if pets.isEmpty {
            pets = [Pet.mockBlob(name: "Blob", canUseEssence: true, windPoints: 30)]
        }
        #endif
    }

    // MARK: - Create

    /// Creates a new pet (starts as blob).
    @discardableResult
    func create(
        name: String,
        purpose: String?,
        preset: WindPreset = .default,
        limitedSources: [LimitedSource] = []
    ) -> Pet {
        let pet = Pet(
            name: name,
            evolutionHistory: EvolutionHistory(),
            purpose: purpose,
            preset: preset,
            limitedSources: limitedSources
        )
        pets.append(pet)
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
        if let data = SharedDefaults.data(forKey: DefaultsKeys.activePets),
           let dtos = try? JSONDecoder().decode([PetDTO].self, from: data) {
            pets = dtos.map { Pet(from: $0) }
        }
    }

    func saveActivePets() {
        let dtos = pets.map { PetDTO(from: $0) }
        if let data = try? JSONEncoder().encode(dtos) {
            SharedDefaults.setData(data, forKey: DefaultsKeys.activePets)
        }
    }
}

// MARK: - Mock Data

extension PetManager {
    static func mock(withPets: Bool = true) -> PetManager {
        let manager = PetManager()
        if withPets {
            manager.pets = [Pet.mock(), Pet.mockWithBreak()]
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
