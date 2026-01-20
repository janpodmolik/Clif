import Foundation

/// Codable DTO for DynamicPet persistence.
struct DynamicPetDTO: Codable {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let windPoints: Double
    let lastThresholdMinutes: Int
    let activeBreak: ActiveBreak?
    let config: DynamicModeConfig
    let dailyStats: [DailyUsageStat]
    let limitedSources: [LimitedSource]
    let breakHistory: [CompletedBreak]

    init(from pet: DynamicPet) {
        self.id = pet.id
        self.name = pet.name
        self.evolutionHistory = pet.evolutionHistory
        self.purpose = pet.purpose
        self.windPoints = pet.windPoints
        self.lastThresholdMinutes = pet.lastThresholdMinutes
        self.activeBreak = pet.activeBreak
        self.config = pet.config
        self.dailyStats = pet.dailyStats
        self.limitedSources = pet.limitedSources
        self.breakHistory = pet.breakHistory
    }
}

extension DynamicPet {
    convenience init(from dto: DynamicPetDTO) {
        self.init(
            id: dto.id,
            name: dto.name,
            evolutionHistory: dto.evolutionHistory,
            purpose: dto.purpose,
            windPoints: dto.windPoints,
            lastThresholdMinutes: dto.lastThresholdMinutes,
            activeBreak: dto.activeBreak,
            config: dto.config,
            dailyStats: dto.dailyStats,
            limitedSources: dto.limitedSources,
            breakHistory: dto.breakHistory
        )
    }
}
