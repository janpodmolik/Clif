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

    var isOnBreak: Bool {
        switch self {
        case .daily: false
        case .dynamic(let pet): pet.activeBreak != nil
        }
    }

    var createdAt: Date { evolutionHistory.createdAt }

    /// Current evolution phase, if pet has essence and is at phase 1+.
    var phase: EvolutionPhase? {
        switch self {
        case .daily(let pet): pet.phase
        case .dynamic(let pet): pet.phase
        }
    }

    // MARK: - Evolution Timing (delegated from PetEvolvable)

    /// True if blob can use essence (at least 1 day old).
    var canUseEssence: Bool {
        switch self {
        case .daily(let pet): pet.canUseEssence
        case .dynamic(let pet): pet.canUseEssence
        }
    }

    /// Days until essence can be used (for blob pets).
    var daysUntilEssence: Int? {
        switch self {
        case .daily(let pet): pet.daysUntilEssence
        case .dynamic(let pet): pet.daysUntilEssence
        }
    }

    /// Days until next evolution.
    var daysUntilEvolution: Int? {
        switch self {
        case .daily(let pet): pet.daysUntilEvolution
        case .dynamic(let pet): pet.daysUntilEvolution
        }
    }

    /// True if evolution/essence button should be shown.
    var isEvolutionAvailable: Bool {
        isBlob ? canUseEssence : canEvolve
    }

    /// Days until next milestone (evolution or essence), if not yet available.
    var daysUntilNextMilestone: Int? {
        isBlob ? daysUntilEssence : daysUntilEvolution
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

    /// Marks pet as blown away.
    func blowAway() {
        switch self {
        case .daily(let pet): pet.blowAway()
        case .dynamic(let pet): pet.blowAway()
        }
    }

    /// Applies essence to a blob pet.
    func applyEssence(_ essence: Essence) {
        switch self {
        case .daily(let pet): pet.applyEssence(essence)
        case .dynamic(let pet): pet.applyEssence(essence)
        }
    }

    /// Evolves the pet to the next phase.
    func evolve() {
        switch self {
        case .daily(let pet): pet.evolve()
        case .dynamic(let pet): pet.evolve()
        }
    }
}
