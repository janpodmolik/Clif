import Foundation

@Observable
final class PetManager {
    // MARK: - Private Storage

    private var dailyPets: [DailyPet] = []
    private var dynamicPets: [DynamicPet] = []
    private var archivedDailyPets: [ArchivedDailyPet] = []
    private var archivedDynamicPets: [ArchivedDynamicPet] = []

    // MARK: - Public API

    /// All active pets as unified list, sorted by creation date (newest first).
    var activePets: [ActivePet] {
        let daily = dailyPets.map { ActivePet.daily($0) }
        let dynamic = dynamicPets.map { ActivePet.dynamic($0) }
        return (daily + dynamic).sorted { $0.createdAt > $1.createdAt }
    }

    /// Currently selected pet for display (first in list).
    var currentPet: ActivePet? {
        activePets.first
    }

    /// Current daily pet (for backwards compatibility with existing UI).
    /// TODO: Migrate UI to use ActivePet and remove this.
    var currentDailyPet: DailyPet? {
        dailyPets.first
    }

    /// All archived pets that weren't blown (for Hall of Fame).
    var completedPets: [ArchivedDailyPet] {
        archivedDailyPets.filter { !$0.isBlown }
    }

    /// All archived daily pets.
    var allArchivedDailyPets: [ArchivedDailyPet] {
        archivedDailyPets
    }

    /// All archived dynamic pets.
    var allArchivedDynamicPets: [ArchivedDynamicPet] {
        archivedDynamicPets
    }

    // MARK: - Init

    init() {
        loadActivePets()
        loadArchivedPets()

        #if DEBUG
        if dailyPets.isEmpty && dynamicPets.isEmpty {
            dailyPets = [DailyPet.mockBlob(name: "Blob", canUseEssence: true, todayUsedMinutes: 100, dailyLimitMinutes: 120)]
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
        dailyPets.append(pet)
        saveActivePets()
        return pet
    }

    /// Creates a new Dynamic pet (starts as blob).
    @discardableResult
    func createDynamic(name: String, purpose: String?, config: DynamicWindConfig = .default) -> DynamicPet {
        let pet = DynamicPet(
            name: name,
            evolutionHistory: EvolutionHistory(),
            purpose: purpose,
            config: config
        )
        dynamicPets.append(pet)
        saveActivePets()
        return pet
    }

    // MARK: - Lookup

    /// Finds an active pet by ID.
    func pet(by id: UUID) -> ActivePet? {
        if let daily = dailyPets.first(where: { $0.id == id }) {
            return .daily(daily)
        }
        if let dynamic = dynamicPets.first(where: { $0.id == id }) {
            return .dynamic(dynamic)
        }
        return nil
    }

    /// Finds a daily pet by ID.
    func dailyPet(by id: UUID) -> DailyPet? {
        dailyPets.first { $0.id == id }
    }

    /// Finds a dynamic pet by ID.
    func dynamicPet(by id: UUID) -> DynamicPet? {
        dynamicPets.first { $0.id == id }
    }

    // MARK: - Archive

    /// Archives an active pet (moves to archived list).
    func archive(id: UUID) {
        if let index = dailyPets.firstIndex(where: { $0.id == id }) {
            let pet = dailyPets[index]
            let archived = ArchivedDailyPet(archiving: pet)
            archivedDailyPets.insert(archived, at: 0)
            dailyPets.remove(at: index)
            saveActivePets()
            saveArchivedPets()
            return
        }

        if let index = dynamicPets.firstIndex(where: { $0.id == id }) {
            let pet = dynamicPets[index]
            let archived = ArchivedDynamicPet(archiving: pet)
            archivedDynamicPets.insert(archived, at: 0)
            dynamicPets.remove(at: index)
            saveActivePets()
            saveArchivedPets()
        }
    }

    /// Blows away a pet and archives it.
    func blowAway(id: UUID) {
        if let pet = dailyPets.first(where: { $0.id == id }) {
            pet.blowAway()
            archive(id: id)
            return
        }

        if let pet = dynamicPets.first(where: { $0.id == id }) {
            pet.blowAway()
            archive(id: id)
        }
    }

    // MARK: - Delete

    /// Removes an active pet without archiving.
    func delete(id: UUID) {
        if dailyPets.contains(where: { $0.id == id }) {
            dailyPets.removeAll { $0.id == id }
            saveActivePets()
            return
        }

        if dynamicPets.contains(where: { $0.id == id }) {
            dynamicPets.removeAll { $0.id == id }
            saveActivePets()
        }
    }

    /// Removes an archived pet.
    func deleteArchived(id: UUID) {
        if archivedDailyPets.contains(where: { $0.id == id }) {
            archivedDailyPets.removeAll { $0.id == id }
            saveArchivedPets()
            return
        }

        if archivedDynamicPets.contains(where: { $0.id == id }) {
            archivedDynamicPets.removeAll { $0.id == id }
            saveArchivedPets()
        }
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
        if let data = SharedDefaults.data(forKey: DefaultsKeys.activeDailyPets),
           let dtos = try? JSONDecoder().decode([DailyPetDTO].self, from: data) {
            dailyPets = dtos.map { DailyPet(from: $0) }
        }

        if let data = SharedDefaults.data(forKey: DefaultsKeys.activeDynamicPets),
           let dtos = try? JSONDecoder().decode([DynamicPetDTO].self, from: data) {
            dynamicPets = dtos.map { DynamicPet(from: $0) }
        }
    }

    func saveActivePets() {
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

// MARK: - Persistence (Archived → FileManager)

private extension PetManager {
    static let archivedDailyPetsURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("archived_daily_pets.json")
    }()

    static let archivedDynamicPetsURL: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("archived_dynamic_pets.json")
    }()

    func loadArchivedPets() {
        // Load archived daily pets
        if let data = try? Data(contentsOf: Self.archivedDailyPetsURL),
           let pets = try? JSONDecoder().decode([ArchivedDailyPet].self, from: data) {
            archivedDailyPets = pets
        } else if let legacyData = SharedDefaults.data(forKey: DefaultsKeys.archivedPets),
                  let pets = try? JSONDecoder().decode([ArchivedDailyPet].self, from: legacyData) {
            // Migration from legacy SharedDefaults
            archivedDailyPets = pets
            saveArchivedPets()
            SharedDefaults.removeObject(forKey: DefaultsKeys.archivedPets)
        }

        // Load archived dynamic pets
        if let data = try? Data(contentsOf: Self.archivedDynamicPetsURL),
           let pets = try? JSONDecoder().decode([ArchivedDynamicPet].self, from: data) {
            archivedDynamicPets = pets
        }
    }

    func saveArchivedPets() {
        if let data = try? JSONEncoder().encode(archivedDailyPets) {
            try? data.write(to: Self.archivedDailyPetsURL)
        }

        if let data = try? JSONEncoder().encode(archivedDynamicPets) {
            try? data.write(to: Self.archivedDynamicPetsURL)
        }
    }
}

// MARK: - Mock Data

extension PetManager {
    static func mock(
        withDailyPets: Bool = true,
        withDynamicPets: Bool = false,
        withArchivedDailyPets: Bool = true,
        withArchivedDynamicPets: Bool = false
    ) -> PetManager {
        let manager = PetManager()
        manager.dailyPets = withDailyPets ? DailyPet.mockList() : []
        manager.dynamicPets = withDynamicPets ? [.mock(), .mockWithBreak()] : []
        manager.archivedDailyPets = withArchivedDailyPets ? ArchivedDailyPet.mockList() : []
        manager.archivedDynamicPets = withArchivedDynamicPets ? ArchivedDynamicPet.mockList() : []
        return manager
    }
}

import SwiftUI

#Preview {
    ContentView()
        .environment(PetManager.mock(withDailyPets: false))
}
