import Foundation

/// Type-safe wrapper for active pets, enabling UI routing and unified collection handling.
enum ActivePet: Identifiable {
    case daily(DailyPet)
    case dynamic(DynamicPet)

    var id: UUID {
        switch self {
        case .daily(let pet): pet.id
        case .dynamic(let pet): pet.id
        }
    }

    // MARK: - PetPresentable Properties

    var name: String {
        switch self {
        case .daily(let pet): pet.name
        case .dynamic(let pet): pet.name
        }
    }

    var purpose: String? {
        switch self {
        case .daily(let pet): pet.purpose
        case .dynamic(let pet): pet.purpose
        }
    }

    var windProgress: CGFloat {
        switch self {
        case .daily(let pet): pet.windProgress
        case .dynamic(let pet): pet.windProgress
        }
    }

    var windLevel: WindLevel {
        .from(progress: windProgress)
    }

    var mood: Mood {
        Mood(from: windLevel)
    }

    // MARK: - PetEvolvable Properties

    var evolutionHistory: EvolutionHistory {
        switch self {
        case .daily(let pet): pet.evolutionHistory
        case .dynamic(let pet): pet.evolutionHistory
        }
    }

    var essence: Essence? { evolutionHistory.essence }
    var currentPhase: Int { evolutionHistory.currentPhase }
    var isBlob: Bool { evolutionHistory.isBlob }
    var canEvolve: Bool { evolutionHistory.canEvolve }
    var isBlown: Bool { evolutionHistory.isBlown }

    var createdAt: Date { evolutionHistory.createdAt }

    // MARK: - Type Checks

    var isDaily: Bool {
        if case .daily = self { return true }
        return false
    }

    var isDynamic: Bool {
        if case .dynamic = self { return true }
        return false
    }

    // MARK: - Type Access

    var asDaily: DailyPet? {
        if case .daily(let pet) = self { return pet }
        return nil
    }

    var asDynamic: DynamicPet? {
        if case .dynamic(let pet) = self { return pet }
        return nil
    }
}

// MARK: - Convenience

extension ActivePet {
    /// Asset name for current evolution state and mood.
    func assetName(for mood: Mood) -> String {
        switch self {
        case .daily(let pet): pet.assetName(for: mood)
        case .dynamic(let pet): pet.assetName(for: mood)
        }
    }
}
