import Foundation

struct ActivePet: Identifiable, Equatable {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let streak: Int
    let windLevel: WindLevel
    let usedMinutes: Int
    let limitMinutes: Int
    let weeklyStats: BlockedAppsWeeklyStats
    let blockedAppCount: Int

    var essence: Essence { evolutionHistory.essence }
    var currentPhase: Int { evolutionHistory.currentPhase }
    var canEvolve: Bool { evolutionHistory.canEvolve }

    var daysUntilEvolution: Int? {
        guard !evolutionHistory.canEvolve else { return nil }
        let daysSinceCreation = Calendar.current.dateComponents(
            [.day],
            from: evolutionHistory.createdAt,
            to: Date()
        ).day ?? 0
        let daysPerPhase = 7
        let nextEvolutionDay = evolutionHistory.currentPhase * daysPerPhase
        let remaining = nextEvolutionDay - daysSinceCreation
        return remaining > 0 ? remaining : nil
    }

    init(
        id: UUID = UUID(),
        name: String,
        evolutionHistory: EvolutionHistory,
        purpose: String?,
        streak: Int,
        windLevel: WindLevel,
        usedMinutes: Int,
        limitMinutes: Int,
        weeklyStats: BlockedAppsWeeklyStats,
        blockedAppCount: Int
    ) {
        self.id = id
        self.name = name
        self.evolutionHistory = evolutionHistory
        self.purpose = purpose
        self.streak = streak
        self.windLevel = windLevel
        self.usedMinutes = usedMinutes
        self.limitMinutes = limitMinutes
        self.weeklyStats = weeklyStats
        self.blockedAppCount = blockedAppCount
    }
}

// MARK: - Mock Data

extension ActivePet {
    static func mock(
        name: String = "Fern",
        phase: Int = 2,
        streak: Int = 12,
        windLevel: WindLevel = .medium,
        usedMinutes: Int = 45,
        limitMinutes: Int = 120
    ) -> ActivePet {
        let calendar = Calendar.current
        let createdAt = calendar.date(byAdding: .day, value: -streak, to: Date()) ?? Date()

        var events: [EvolutionEvent] = []
        if phase > 1 {
            for p in 2...phase {
                let offset = p * 7 - streak
                let date = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                events.append(EvolutionEvent(fromPhase: p - 1, toPhase: p, date: date))
            }
        }

        return ActivePet(
            name: name,
            evolutionHistory: EvolutionHistory(
                createdAt: createdAt,
                essence: .plant,
                events: events
            ),
            purpose: "Social Media",
            streak: streak,
            windLevel: windLevel,
            usedMinutes: usedMinutes,
            limitMinutes: limitMinutes,
            weeklyStats: .mock(),
            blockedAppCount: 8
        )
    }

    static func mockList() -> [ActivePet] {
        [
            .mock(name: "Fern", phase: 2, streak: 12, windLevel: .low, usedMinutes: 25, limitMinutes: 120),
            .mock(name: "Ivy", phase: 3, streak: 19, windLevel: .medium, usedMinutes: 67, limitMinutes: 90)
        ]
    }
}
