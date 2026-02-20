import Foundation

/// Archived version of a Pet for history/graveyard.
struct ArchivedPet: Codable, Identifiable, Equatable, PetEvolvable {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let archivedAt: Date
    let archiveReason: ArchiveReason

    // MARK: - Stats

    let dailyStats: [DailyUsageStat]

    // MARK: - Wind & Breaks

    /// Break history from the pet's lifetime.
    let breakHistory: [CompletedBreak]

    /// Peak wind points reached during lifetime.
    let peakWindPoints: Double

    /// Total break minutes completed.
    let totalBreakMinutes: Double

    /// Total wind points decreased from breaks.
    let totalWindDecreased: Double

    /// Wind preset used for this pet.
    let preset: WindPreset

    // MARK: - Computed

    /// Total days tracked.
    var totalDays: Int { dailyStats.count }

    /// Alias for currentPhase - the phase when pet was archived.
    var finalPhase: Int { currentPhase }

    /// Number of successful breaks.
    var successfulBreaks: Int {
        breakHistory.filter { !$0.wasViolated }.count
    }

    /// Number of violated breaks.
    var violatedBreaks: Int {
        breakHistory.filter(\.wasViolated).count
    }

    /// Full usage stats for history display.
    var fullStats: FullUsageStats {
        FullUsageStats(days: dailyStats)
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        name: String,
        evolutionHistory: EvolutionHistory,
        purpose: String?,
        archivedAt: Date = Date(),
        archiveReason: ArchiveReason,
        dailyStats: [DailyUsageStat] = [],
        breakHistory: [CompletedBreak] = [],
        peakWindPoints: Double = 0,
        totalBreakMinutes: Double = 0,
        totalWindDecreased: Double = 0,
        preset: WindPreset = .default
    ) {
        self.id = id
        self.name = name
        self.evolutionHistory = evolutionHistory
        self.purpose = purpose
        self.archivedAt = archivedAt
        self.archiveReason = archiveReason
        self.dailyStats = dailyStats
        self.breakHistory = breakHistory
        self.peakWindPoints = peakWindPoints
        self.totalBreakMinutes = totalBreakMinutes
        self.totalWindDecreased = totalWindDecreased
        self.preset = preset
    }
}

// MARK: - Archiving from Pet

extension ArchivedPet {
    /// Creates an archived pet from an active Pet.
    init(archiving pet: Pet, reason: ArchiveReason, archivedAt: Date = Date()) {
        self.init(
            id: pet.id,
            name: pet.name,
            evolutionHistory: pet.evolutionHistory,
            purpose: pet.purpose,
            archivedAt: archivedAt,
            archiveReason: reason,
            dailyStats: pet.dailyStats,
            breakHistory: pet.breakHistory,
            peakWindPoints: pet.peakWindPoints,
            totalBreakMinutes: pet.totalBreakMinutes,
            totalWindDecreased: pet.totalWindDecreased,
            preset: pet.preset
        )
    }
}

// MARK: - Mock Data

extension ArchivedPet {
    static func mock(
        name: String = "Windy",
        phase: Int = 3,
        essence: Essence? = .plant,
        archiveReason: ArchiveReason = .blown,
        totalDays: Int = 5
    ) -> ArchivedPet {
        let petId = UUID()
        let calendar = Calendar.current
        let archivedAt = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()

        // Generate some mock breaks
        let breakHistory: [CompletedBreak] = (0..<3).map { i in
            let startDate = calendar.date(byAdding: .hour, value: -(i * 4), to: archivedAt) ?? archivedAt
            let endDate = startDate.addingTimeInterval(30 * 60)
            return CompletedBreak(
                type: [.free, .committed][i % 2],
                startedAt: startDate,
                endedAt: endDate,
                windAtStart: Double(50 + i * 10),
                windDecreased: Double(10 + i * 5),
                wasViolated: i == 2
            )
        }

        return ArchivedPet(
            id: petId,
            name: name,
            evolutionHistory: .mock(
                phase: phase,
                essence: essence,
                totalDays: totalDays,
                isBlown: archiveReason == .blown
            ),
            purpose: "Social Media",
            archivedAt: archivedAt,
            archiveReason: archiveReason,
            dailyStats: DailyUsageStat.mockList(petId: petId, days: totalDays),
            breakHistory: breakHistory,
            peakWindPoints: 95,
            totalBreakMinutes: 90,
            totalWindDecreased: 35
        )
    }

    static func mockList() -> [ArchivedPet] {
        [
            .mock(name: "Storm", phase: 4, archiveReason: .completed, totalDays: 10),
            .mock(name: "Breeze", phase: 3, archiveReason: .blown, totalDays: 5),
            .mock(name: "Gust", phase: 2, archiveReason: .blown, totalDays: 2)
        ]
    }

    static func mockBlob(name: String = "Blobby") -> ArchivedPet {
        ArchivedPet(
            name: name,
            evolutionHistory: .mock(phase: 0, essence: nil, totalDays: 1, isBlown: false),
            purpose: nil,
            archiveReason: .manual
        )
    }
}
