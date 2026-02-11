import Foundation

/// DTO for the `archived_pets` Supabase table.
/// Maps between local ArchivedPet and Supabase JSONB columns.
struct ArchivedPetSupabaseDTO: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let purpose: String?
    let preset: String
    let archivedAt: Date
    let archiveReason: String
    let peakWindPoints: Double
    let totalBreakMinutes: Double
    let totalWindDecreased: Double
    let evolutionHistory: EvolutionHistory
    let dailyStats: [DailyUsageStat]
    let breakHistory: [CompletedBreak]
    let hourlyAggregate: HourlyAggregate?
    let hourlyPerDay: [DailyHourlyBreakdown]
    let schemaVersion: Int

    enum CodingKeys: String, CodingKey {
        case id, name, purpose, preset
        case userId = "user_id"
        case archivedAt = "archived_at"
        case archiveReason = "archive_reason"
        case peakWindPoints = "peak_wind_points"
        case totalBreakMinutes = "total_break_minutes"
        case totalWindDecreased = "total_wind_decreased"
        case evolutionHistory = "evolution_history"
        case dailyStats = "daily_stats"
        case breakHistory = "break_history"
        case hourlyAggregate = "hourly_aggregate"
        case hourlyPerDay = "hourly_per_day"
        case schemaVersion = "schema_version"
    }

    /// Creates a Supabase DTO from a local ArchivedPet + hourly data.
    init(
        from archivedPet: ArchivedPet,
        userId: UUID,
        hourlyAggregate: HourlyAggregate? = nil,
        hourlyPerDay: [DailyHourlyBreakdown] = []
    ) {
        self.id = archivedPet.id
        self.userId = userId
        self.name = archivedPet.name
        self.purpose = archivedPet.purpose
        self.preset = archivedPet.preset.rawValue
        self.archivedAt = archivedPet.archivedAt
        self.archiveReason = archivedPet.archiveReason.rawValue
        self.peakWindPoints = archivedPet.peakWindPoints
        self.totalBreakMinutes = archivedPet.totalBreakMinutes
        self.totalWindDecreased = archivedPet.totalWindDecreased
        self.evolutionHistory = archivedPet.evolutionHistory
        self.dailyStats = archivedPet.dailyStats
        self.breakHistory = archivedPet.breakHistory
        self.hourlyAggregate = hourlyAggregate
        self.hourlyPerDay = hourlyPerDay
        self.schemaVersion = 1
    }
}

// MARK: - Conversion to ArchivedPet

extension ArchivedPet {
    /// Creates an ArchivedPet from a Supabase cloud DTO (used during restore).
    init(from supabaseDTO: ArchivedPetSupabaseDTO) {
        self.init(
            id: supabaseDTO.id,
            name: supabaseDTO.name,
            evolutionHistory: supabaseDTO.evolutionHistory,
            purpose: supabaseDTO.purpose,
            archivedAt: supabaseDTO.archivedAt,
            archiveReason: ArchiveReason(rawValue: supabaseDTO.archiveReason) ?? .manual,
            dailyStats: supabaseDTO.dailyStats,
            breakHistory: supabaseDTO.breakHistory,
            peakWindPoints: supabaseDTO.peakWindPoints,
            totalBreakMinutes: supabaseDTO.totalBreakMinutes,
            totalWindDecreased: supabaseDTO.totalWindDecreased,
            preset: WindPreset(rawValue: supabaseDTO.preset) ?? .balanced
        )
    }
}
