import Foundation

@Observable
final class PetStore {
    private(set) var archivedPets: [ArchivedPet] = []

    /// Peti co nebyli blown (pro Hall of Fame)
    var completedPets: [ArchivedPet] {
        archivedPets.filter { !$0.isBlown }
    }

    init() {
        load()
    }

    func archive(_ pet: ArchivedPet) {
        archivedPets.insert(pet, at: 0)
        save()
    }

    func delete(_ pet: ArchivedPet) {
        archivedPets.removeAll { $0.id == pet.id }
        save()
    }

    private func load() {
        guard let data = SharedDefaults.data(forKey: DefaultsKeys.archivedPets) else { return }
        archivedPets = (try? JSONDecoder().decode([ArchivedPet].self, from: data)) ?? []
    }

    private func save() {
        let data = try? JSONEncoder().encode(archivedPets)
        SharedDefaults.setData(data, forKey: DefaultsKeys.archivedPets)
    }
}
