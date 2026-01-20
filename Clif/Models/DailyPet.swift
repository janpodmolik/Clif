import FamilyControls
import Foundation
import ManagedSettings

@Observable
final class DailyPet: Identifiable, PetPresentable, PetWithSources {
    let id: UUID
    let name: String
    private(set) var evolutionHistory: EvolutionHistory
    let purpose: String?
    var todayUsedMinutes: Int
    let dailyLimitMinutes: Int

    var dailyStats: [DailyUsageStat]
    var limitedSources: [LimitedSource]

    // MARK: - Wind (Daily mode uses usage/limit ratio)

    /// Usage progress (0-1) for wind animations, clamped to 1.0 max.
    var windProgress: CGFloat {
        guard dailyLimitMinutes > 0 else { return 0 }
        let raw = CGFloat(todayUsedMinutes) / CGFloat(dailyLimitMinutes)
        return min(raw, 1.0)
    }

    // MARK: - Stats with Limit

    var weeklyStats: WeeklyUsageStats {
        let lastSevenDays = Array(dailyStats.suffix(7))
        return WeeklyUsageStats(days: lastSevenDays, dailyLimitMinutes: dailyLimitMinutes)
    }

    var fullStats: FullUsageStats {
        FullUsageStats(days: dailyStats, dailyLimitMinutes: dailyLimitMinutes)
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

        // Log snapshot
        let windPointsValue = Double(windProgress * 100)
        SnapshotLogging.logBlowAway(
            petId: id,
            mode: .daily,
            windPoints: windPointsValue
        )
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
        limitedSources: [LimitedSource] = []
    ) {
        self.id = id
        self.name = name
        self.evolutionHistory = evolutionHistory
        self.purpose = purpose
        self.todayUsedMinutes = todayUsedMinutes
        self.dailyLimitMinutes = dailyLimitMinutes
        self.dailyStats = dailyStats
        self.limitedSources = limitedSources
    }
}

// MARK: - Mock Data

extension DailyPet {
    static func mock(
        name: String = "Fern",
        phase: Int = 2,
        essence: Essence? = .plant,
        todayUsedMinutes: Int = 45,
        dailyLimitMinutes: Int = 120,
        totalDays: Int = 14
    ) -> DailyPet {
        let petId = UUID()
        let dailyStats = DailyUsageStat.mockList(
            petId: petId,
            days: totalDays,
            dailyLimitMinutes: dailyLimitMinutes
        )

        return DailyPet(
            id: petId,
            name: name,
            evolutionHistory: .mock(phase: phase, essence: essence, totalDays: totalDays),
            purpose: "Social Media",
            todayUsedMinutes: todayUsedMinutes,
            dailyLimitMinutes: dailyLimitMinutes,
            dailyStats: dailyStats,
            limitedSources: LimitedSource.mockList(days: totalDays)
        )
    }

    /// Mock blob pet (no essence yet)
    static func mockBlob(
        name: String = "Blobby",
        canUseEssence: Bool = false,
        todayUsedMinutes: Int = 15,
        dailyLimitMinutes: Int = 120
    ) -> DailyPet {
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

    static func mockList() -> [DailyPet] {
        [
            .mock(name: "Fern", phase: 2, todayUsedMinutes: 25, dailyLimitMinutes: 120),
            .mock(name: "Ivy", phase: 3, todayUsedMinutes: 67, dailyLimitMinutes: 90)
        ]
    }
}
