import Foundation

/// DTO for the `active_pets` Supabase table.
/// Maps between local PetDTO and Supabase JSONB columns.
struct ActivePetSupabaseDTO: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let purpose: String?
    let preset: String
    let limitedSourceChangesCount: Int
    let evolutionHistory: EvolutionHistory
    let dailyStats: [DailyUsageStat]
    let limitedSources: [LimitedSource]
    let breakHistory: [CompletedBreak]
    let hourlyAggregate: HourlyAggregate?
    let hourlyPerDay: [DailyHourlyBreakdown]
    let schemaVersion: Int
    let updatedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, purpose, preset
        case userId = "user_id"
        case limitedSourceChangesCount = "limited_source_changes_count"
        case evolutionHistory = "evolution_history"
        case dailyStats = "daily_stats"
        case limitedSources = "limited_sources"
        case breakHistory = "break_history"
        case hourlyAggregate = "hourly_aggregate"
        case hourlyPerDay = "hourly_per_day"
        case schemaVersion = "schema_version"
        case updatedAt = "updated_at"
    }

    /// Creates a Supabase DTO from local PetDTO + sync data.
    init(
        from petDTO: PetDTO,
        userId: UUID,
        hourlyAggregate: HourlyAggregate?,
        hourlyPerDay: [DailyHourlyBreakdown]
    ) {
        self.id = petDTO.id
        self.userId = userId
        self.name = petDTO.name
        self.purpose = petDTO.purpose
        self.preset = petDTO.preset.rawValue
        self.limitedSourceChangesCount = petDTO.limitedSourceChangesCount
        self.evolutionHistory = petDTO.evolutionHistory
        self.dailyStats = petDTO.dailyStats
        self.limitedSources = petDTO.limitedSources
        self.breakHistory = petDTO.breakHistory
        self.hourlyAggregate = hourlyAggregate
        self.hourlyPerDay = hourlyPerDay
        self.schemaVersion = 1
        self.updatedAt = Date()
    }
}

// MARK: - Conversion to PetDTO

extension PetDTO {
    /// Creates a PetDTO from a Supabase cloud DTO (used during restore).
    init(from supabaseDTO: ActivePetSupabaseDTO) {
        self.init(
            id: supabaseDTO.id,
            name: supabaseDTO.name,
            evolutionHistory: supabaseDTO.evolutionHistory,
            purpose: supabaseDTO.purpose,
            preset: WindPreset(rawValue: supabaseDTO.preset) ?? .balanced,
            dailyStats: supabaseDTO.dailyStats,
            limitedSources: supabaseDTO.limitedSources,
            limitedSourceChangesCount: supabaseDTO.limitedSourceChangesCount,
            breakHistory: supabaseDTO.breakHistory
        )
    }
}
