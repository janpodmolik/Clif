import Foundation

/// Archived version of a DynamicPet for history/graveyard.
struct ArchivedDynamicPet: Codable, Identifiable, Equatable, PetWithStats {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let archivedAt: Date

    // MARK: - PetWithStats

    let dailyStats: [DailyUsageStat]
    let appUsage: [AppUsage]

    // MARK: - Dynamic-specific

    /// Break history from the pet's lifetime.
    let breakHistory: [CompletedBreak]

    /// Peak wind points reached during lifetime.
    let peakWindPoints: Double

    /// Total break minutes completed.
    let totalBreakMinutes: Double

    /// Total wind points decreased from breaks.
    let totalWindDecreased: Double

    /// Configuration used for this pet.
    let config: DynamicWindConfig

    // MARK: - Computed

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

    // MARK: - Init

    init(
        id: UUID = UUID(),
        name: String,
        evolutionHistory: EvolutionHistory,
        purpose: String?,
        archivedAt: Date = Date(),
        dailyStats: [DailyUsageStat] = [],
        appUsage: [AppUsage] = [],
        breakHistory: [CompletedBreak] = [],
        peakWindPoints: Double = 0,
        totalBreakMinutes: Double = 0,
        totalWindDecreased: Double = 0,
        config: DynamicWindConfig = .default
    ) {
        self.id = id
        self.name = name
        self.evolutionHistory = evolutionHistory
        self.purpose = purpose
        self.archivedAt = archivedAt
        self.dailyStats = dailyStats
        self.appUsage = appUsage
        self.breakHistory = breakHistory
        self.peakWindPoints = peakWindPoints
        self.totalBreakMinutes = totalBreakMinutes
        self.totalWindDecreased = totalWindDecreased
        self.config = config
    }
}

// MARK: - Archiving from DynamicPet

extension ArchivedDynamicPet {
    /// Creates an archived pet from an active DynamicPet.
    init(archiving pet: DynamicPet, archivedAt: Date = Date()) {
        self.init(
            id: pet.id,
            name: pet.name,
            evolutionHistory: pet.evolutionHistory,
            purpose: pet.purpose,
            archivedAt: archivedAt,
            dailyStats: pet.dailyStats,
            appUsage: pet.appUsage,
            breakHistory: pet.breakHistory,
            peakWindPoints: pet.peakWindPoints,
            totalBreakMinutes: pet.totalBreakMinutes,
            totalWindDecreased: pet.totalWindDecreased,
            config: pet.config
        )
    }
}

// MARK: - Mock Data

extension ArchivedDynamicPet {
    static func mock(
        name: String = "Windy",
        phase: Int = 3,
        isBlown: Bool = true,
        totalDays: Int = 5
    ) -> ArchivedDynamicPet {
        let petId = UUID()
        let calendar = Calendar.current
        let archivedAt = calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()

        // Generate some mock breaks
        let breakHistory: [CompletedBreak] = (0..<3).map { i in
            let startDate = calendar.date(byAdding: .hour, value: -(i * 4), to: archivedAt) ?? archivedAt
            let endDate = startDate.addingTimeInterval(30 * 60)
            return CompletedBreak(
                type: [.free, .committed, .hardcore][i % 3],
                startedAt: startDate,
                endedAt: endDate,
                windAtStart: Double(50 + i * 10),
                windDecreased: Double(10 + i * 5),
                wasViolated: i == 2
            )
        }

        return ArchivedDynamicPet(
            id: petId,
            name: name,
            evolutionHistory: .mock(phase: phase, essence: .plant, totalDays: totalDays, isBlown: isBlown),
            purpose: "Social Media",
            archivedAt: archivedAt,
            dailyStats: DailyUsageStat.mockList(petId: petId, days: totalDays),
            appUsage: AppUsage.mockList(days: totalDays, petId: petId),
            breakHistory: breakHistory,
            peakWindPoints: 95,
            totalBreakMinutes: 90,
            totalWindDecreased: 35
        )
    }

    static func mockList() -> [ArchivedDynamicPet] {
        [
            .mock(name: "Storm", phase: 4, isBlown: false, totalDays: 10),
            .mock(name: "Breeze", phase: 3, isBlown: true, totalDays: 5),
            .mock(name: "Gust", phase: 2, isBlown: true, totalDays: 2)
        ]
    }
}
