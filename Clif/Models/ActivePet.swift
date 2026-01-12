import FamilyControls
import Foundation
import ManagedSettings

struct ActivePet: Identifiable, Equatable {
    let id: UUID
    let name: String
    let evolutionHistory: EvolutionHistory
    let purpose: String?
    let windLevel: WindLevel
    let todayUsedMinutes: Int
    let dailyLimitMinutes: Int
    let dailyStats: [DailyUsageStat]
    let appUsage: [AppUsage]
    let applicationTokens: Set<ApplicationToken>
    let categoryTokens: Set<ActivityCategoryToken>

    var totalDays: Int { dailyStats.count }

    var limitedAppCount: Int {
        applicationTokens.count + categoryTokens.count
    }

    var weeklyStats: WeeklyUsageStats {
        let lastSevenDays = Array(dailyStats.suffix(7))
        return WeeklyUsageStats(days: lastSevenDays, dailyLimitMinutes: dailyLimitMinutes)
    }

    var fullStats: FullUsageStats {
        FullUsageStats(days: dailyStats, dailyLimitMinutes: dailyLimitMinutes)
    }

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
        windLevel: WindLevel,
        todayUsedMinutes: Int,
        dailyLimitMinutes: Int,
        dailyStats: [DailyUsageStat] = [],
        appUsage: [AppUsage] = [],
        applicationTokens: Set<ApplicationToken> = [],
        categoryTokens: Set<ActivityCategoryToken> = []
    ) {
        self.id = id
        self.name = name
        self.evolutionHistory = evolutionHistory
        self.purpose = purpose
        self.windLevel = windLevel
        self.todayUsedMinutes = todayUsedMinutes
        self.dailyLimitMinutes = dailyLimitMinutes
        self.dailyStats = dailyStats
        self.appUsage = appUsage
        self.applicationTokens = applicationTokens
        self.categoryTokens = categoryTokens
    }
}

// MARK: - Mock Data

extension ActivePet {
    static func mock(
        name: String = "Fern",
        phase: Int = 2,
        windLevel: WindLevel = .medium,
        todayUsedMinutes: Int = 45,
        dailyLimitMinutes: Int = 120,
        totalDays: Int = 14
    ) -> ActivePet {
        let petId = UUID()
        let calendar = Calendar.current
        let createdAt = calendar.date(byAdding: .day, value: -totalDays, to: Date()) ?? Date()

        var events: [EvolutionEvent] = []
        if phase > 1 {
            for p in 2...phase {
                let offset = p * 7 - totalDays
                let date = calendar.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                events.append(EvolutionEvent(fromPhase: p - 1, toPhase: p, date: date))
            }
        }

        // Generate daily stats
        let today = calendar.startOfDay(for: Date())
        let dailyStats = (0..<totalDays).map { dayOffset -> DailyUsageStat in
            let date = calendar.date(byAdding: .day, value: -(totalDays - 1) + dayOffset, to: today)!
            let minutes = Int.random(in: 20...(dailyLimitMinutes + 20))
            return DailyUsageStat(petId: petId, date: date, totalMinutes: minutes)
        }

        return ActivePet(
            id: petId,
            name: name,
            evolutionHistory: EvolutionHistory(
                createdAt: createdAt,
                essence: .plant,
                events: events
            ),
            purpose: "Social Media",
            windLevel: windLevel,
            todayUsedMinutes: todayUsedMinutes,
            dailyLimitMinutes: dailyLimitMinutes,
            dailyStats: dailyStats,
            appUsage: AppUsage.mockList(days: totalDays, petId: petId)
        )
    }

    static func mockList() -> [ActivePet] {
        [
            .mock(name: "Fern", phase: 2, windLevel: .low, todayUsedMinutes: 25, dailyLimitMinutes: 120),
            .mock(name: "Ivy", phase: 3, windLevel: .medium, todayUsedMinutes: 67, dailyLimitMinutes: 90)
        ]
    }
}
