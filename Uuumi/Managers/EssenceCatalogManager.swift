import Foundation

@Observable
final class EssenceCatalogManager {

    // MARK: - State

    private(set) var unlockedEssences: Set<Essence>

    // MARK: - Init

    init() {
        unlockedEssences = Self.loadUnlocked()
    }

    // MARK: - Public API

    func isUnlocked(_ essence: Essence) -> Bool {
        unlockedEssences.contains(essence)
    }

    var catalogEntries: [CatalogEntry] {
        Essence.allCases.map { essence in
            CatalogEntry(
                essence: essence,
                isUnlocked: isUnlocked(essence)
            )
        }
    }

    func unlock(_ essence: Essence) {
        unlockedEssences.insert(essence)
        save()
    }

    // MARK: - Persistence

    private static let storageKey = "unlockedEssences"

    private static func loadUnlocked() -> Set<Essence> {
        guard let rawValues = UserDefaults.standard.stringArray(forKey: storageKey) else {
            return [.plant]
        }
        return Set(rawValues.compactMap { Essence(rawValue: $0) })
    }

    private func save() {
        let rawValues = unlockedEssences.map(\.rawValue)
        UserDefaults.standard.set(rawValues, forKey: Self.storageKey)
    }
}

// MARK: - CatalogEntry

extension EssenceCatalogManager {
    struct CatalogEntry: Identifiable {
        let essence: Essence
        let isUnlocked: Bool

        var id: String { essence.rawValue }
        var evolutionPath: EvolutionPath { .path(for: essence) }
    }
}

// MARK: - Mock

extension EssenceCatalogManager {
    static func mock(allUnlocked: Bool = false) -> EssenceCatalogManager {
        let manager = EssenceCatalogManager()
        if allUnlocked {
            Essence.allCases.forEach { manager.unlockedEssences.insert($0) }
        }
        return manager
    }
}
