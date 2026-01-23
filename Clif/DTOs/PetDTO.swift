import Foundation

/// Codable DTO for Pet persistence.
struct PetDTO: Codable {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let windPoints: Double
    let lastThresholdSeconds: Int
    let activeBreak: ActiveBreak?
    let preset: WindPreset
    let dailyStats: [DailyUsageStat]
    let limitedSources: [LimitedSource]
    let breakHistory: [CompletedBreak]

    init(from pet: Pet) {
        self.id = pet.id
        self.name = pet.name
        self.evolutionHistory = pet.evolutionHistory
        self.purpose = pet.purpose
        self.windPoints = pet.windPoints
        self.lastThresholdSeconds = pet.lastThresholdSeconds
        self.activeBreak = pet.activeBreak
        self.preset = pet.preset
        self.dailyStats = pet.dailyStats
        self.limitedSources = pet.limitedSources
        self.breakHistory = pet.breakHistory
    }
}

extension Pet {
    convenience init(from dto: PetDTO) {
        self.init(
            id: dto.id,
            name: dto.name,
            evolutionHistory: dto.evolutionHistory,
            purpose: dto.purpose,
            windPoints: dto.windPoints,
            lastThresholdSeconds: dto.lastThresholdSeconds,
            activeBreak: dto.activeBreak,
            preset: dto.preset,
            dailyStats: dto.dailyStats,
            limitedSources: dto.limitedSources,
            breakHistory: dto.breakHistory
        )
    }
}
