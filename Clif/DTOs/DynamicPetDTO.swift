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
    let config: DynamicWindConfig
    let dailyStats: [DailyUsageStat]
    let appUsage: [AppUsage]
    let limitedApps: [LimitedApp]
    let limitedCategories: [LimitedCategory]
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
        self.appUsage = pet.appUsage
        self.limitedApps = pet.limitedApps
        self.limitedCategories = pet.limitedCategories
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
            appUsage: dto.appUsage,
            limitedApps: dto.limitedApps,
            limitedCategories: dto.limitedCategories,
            breakHistory: dto.breakHistory
        )
    }
}
