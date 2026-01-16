import FamilyControls
import Foundation
import ManagedSettings

@Observable
final class ActivePet: Identifiable, PetEvolvable {
    let id: UUID
    let name: String
    private(set) var evolutionHistory: EvolutionHistory
    let purpose: String?
    var todayUsedMinutes: Int
    let dailyLimitMinutes: Int

    /// Usage progress (0-1) for wind animations, clamped to 1.0 max.
    /// Values above 1.0 indicate over-limit usage but wind maxes out at 100%.
    var windProgress: CGFloat {
        guard dailyLimitMinutes > 0 else { return 0 }
        let raw = CGFloat(todayUsedMinutes) / CGFloat(dailyLimitMinutes)
        return min(raw, 1.0)
    }

    /// Wind level zone computed from usage progress
    var windLevel: WindLevel {
        WindLevel.from(progress: windProgress)
    }
    var dailyStats: [DailyUsageStat]
    var appUsage: [AppUsage]
    var applicationTokens: Set<ApplicationToken>
    var categoryTokens: Set<ActivityCategoryToken>

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

    /// Days since pet was created
    private var daysSinceCreation: Int {
        Calendar.current.dateComponents(
            [.day],
            from: evolutionHistory.createdAt,
            to: Date()
        ).day ?? 0
    }

    /// True if blob can use essence (at least 1 day old)
    var canUseEssence: Bool {
        guard isBlob else { return false }
        return daysSinceCreation >= 1
    }

    /// Days until essence can be used (for blob pets)
    var daysUntilEssence: Int? {
        guard isBlob, !canUseEssence else { return nil }
        let remaining = 1 - daysSinceCreation
        return remaining > 0 ? remaining : nil
    }

    /// Days until next evolution (1 day per phase)
    var daysUntilEvolution: Int? {
        guard !evolutionHistory.canEvolve else { return nil }
        guard !isBlob else { return nil }
        let daysPerPhase = 1
        let nextEvolutionDay = evolutionHistory.currentPhase * daysPerPhase
        let remaining = nextEvolutionDay - daysSinceCreation
        return remaining > 0 ? remaining : nil
    }

    // MARK: - Mutations

    /// Applies essence to blob, transforming it to phase 1 of the evolution path.
    func applyEssence(_ essence: Essence) {
        guard isBlob else { return }
        evolutionHistory.applyEssence(essence)
    }

    /// Evolves pet to the next phase.
    func evolve() {
        guard canEvolve else { return }
        let nextPhase = evolutionHistory.currentPhase + 1
        evolutionHistory.recordEvolution(to: nextPhase)
    }

    /// Marks pet as blown away.
    func blowAway() {
        guard !isBlown else { return }
        evolutionHistory.markAsBlown()
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        name: String,
        evolutionHistory: EvolutionHistory,
        purpose: String?,
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
        essence: Essence? = .plant,
        todayUsedMinutes: Int = 45,
        dailyLimitMinutes: Int = 120,
        totalDays: Int = 14
    ) -> ActivePet {
        let petId = UUID()
        let calendar = Calendar.current
        let createdAt = calendar.date(byAdding: .day, value: -totalDays, to: Date()) ?? Date()

        var events: [EvolutionEvent] = []
        // Only create events if essence is set and phase > 1
        if essence != nil, phase > 1 {
            for p in 2...phase {
                let offset = p - totalDays
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
                essence: essence,
                events: events
            ),
            purpose: "Social Media",
            todayUsedMinutes: todayUsedMinutes,
            dailyLimitMinutes: dailyLimitMinutes,
            dailyStats: dailyStats,
            appUsage: AppUsage.mockList(days: totalDays, petId: petId)
        )
    }

    /// Mock blob pet (no essence yet)
    static func mockBlob(
        name: String = "Blobby",
        canUseEssence: Bool = false,
        todayUsedMinutes: Int = 15,
        dailyLimitMinutes: Int = 120
    ) -> ActivePet {
        let totalDays = canUseEssence ? 2 : 0
        return mock(
            name: name,
            phase: 0,
            essence: nil,
            todayUsedMinutes: todayUsedMinutes,
            dailyLimitMinutes: dailyLimitMinutes,
            totalDays: totalDays
        )
    }

    static func mockList() -> [ActivePet] {
        [
            .mock(name: "Fern", phase: 2, todayUsedMinutes: 25, dailyLimitMinutes: 120),
            .mock(name: "Ivy", phase: 3, todayUsedMinutes: 67, dailyLimitMinutes: 90)
        ]
    }
}
