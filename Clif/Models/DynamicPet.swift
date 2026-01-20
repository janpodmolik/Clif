import FamilyControls
import Foundation
import ManagedSettings

@Observable
final class DynamicPet: Identifiable, PetPresentable, PetWithSources {
    let id: UUID
    let name: String
    private(set) var evolutionHistory: EvolutionHistory
    let purpose: String?

    /// Current wind points (0-100). At 100, pet blows away.
    var windPoints: Double

    /// Last recorded threshold minutes from DeviceActivityMonitor.
    var lastThresholdMinutes: Int

    /// Currently active break session, if any.
    var activeBreak: ActiveBreak?

    /// Configuration for wind rise/fall behavior.
    let config: DynamicModeConfig

    // MARK: - PetWithSources

    var dailyStats: [DailyUsageStat]
    var limitedSources: [LimitedSource]

    /// Break history for current session.
    var breakHistory: [CompletedBreak]

    /// Full usage stats for history display. Dynamic mode has no fixed daily limit.
    var fullStats: FullUsageStats {
        FullUsageStats(days: dailyStats, dailyLimitMinutes: .max)
    }

    // MARK: - Wind (Dynamic mode uses 0-100 points)

    /// Wind progress for UI (0-1), clamped.
    var windProgress: CGFloat {
        CGFloat(min(max(windPoints / 100.0, 0), 1.0))
    }

    /// Whether pet has been blown away.
    var isBlownAway: Bool {
        windPoints >= 100
    }

    // MARK: - Break Statistics

    /// Total wind points decreased from all breaks.
    var totalWindDecreased: Double {
        breakHistory.reduce(0) { $0 + $1.windDecreased }
    }

    /// Total break minutes completed.
    var totalBreakMinutes: Double {
        breakHistory.reduce(0) { $0 + $1.durationMinutes }
    }

    /// Peak wind points reached.
    var peakWindPoints: Double {
        breakHistory.map(\.windAtStart).max() ?? windPoints
    }

    // MARK: - Mutations

    /// Updates wind based on new threshold minutes from monitor.
    func updateWind(newThresholdMinutes: Int) {
        let deltaMinutes = newThresholdMinutes - lastThresholdMinutes
        guard deltaMinutes > 0 else { return }

        windPoints += Double(deltaMinutes) * config.riseRate
        windPoints = min(windPoints, 100)
        lastThresholdMinutes = newThresholdMinutes

        if windPoints >= 100 {
            blowAway()
        }
    }

    /// Starts a new break session.
    func startBreak(_ breakSession: ActiveBreak) {
        activeBreak = breakSession
    }

    /// Ends current break successfully, applying wind decrease.
    func endBreak() {
        guard let breakSession = activeBreak else { return }

        let decreased = breakSession.windDecreased(for: config)
        let completed = CompletedBreak(
            type: breakSession.type,
            startedAt: breakSession.startedAt,
            endedAt: Date(),
            windAtStart: windPoints,
            windDecreased: decreased,
            wasViolated: false
        )
        breakHistory.append(completed)

        windPoints = max(windPoints - decreased, 0)
        activeBreak = nil
    }

    /// Fails current break (user violated it).
    func failBreak() {
        guard let breakSession = activeBreak else { return }

        let completed = CompletedBreak(
            type: breakSession.type,
            startedAt: breakSession.startedAt,
            endedAt: Date(),
            windAtStart: windPoints,
            windDecreased: 0,
            wasViolated: true
        )
        breakHistory.append(completed)

        // Hardcore penalty: pet blows away
        if breakSession.type == .hardcore {
            windPoints = 100
            blowAway()
        }
        // Free and committed: no wind decrease (windDecreased already set to 0)

        activeBreak = nil
    }

    /// Applies essence to blob.
    func applyEssence(_ essence: Essence) {
        guard isBlob else { return }
        evolutionHistory.applyEssence(essence)
    }

    /// Evolves pet to next phase.
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

    /// Resets wind to 0 (for daily reset).
    func resetWind() {
        windPoints = 0
        lastThresholdMinutes = 0
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        name: String,
        evolutionHistory: EvolutionHistory,
        purpose: String?,
        windPoints: Double = 0,
        lastThresholdMinutes: Int = 0,
        activeBreak: ActiveBreak? = nil,
        config: DynamicModeConfig = .default,
        dailyStats: [DailyUsageStat] = [],
        limitedSources: [LimitedSource] = [],
        breakHistory: [CompletedBreak] = []
    ) {
        self.id = id
        self.name = name
        self.evolutionHistory = evolutionHistory
        self.purpose = purpose
        self.windPoints = windPoints
        self.lastThresholdMinutes = lastThresholdMinutes
        self.activeBreak = activeBreak
        self.config = config
        self.dailyStats = dailyStats
        self.limitedSources = limitedSources
        self.breakHistory = breakHistory
    }
}

// MARK: - CompletedBreak

/// Record of a completed break session.
struct CompletedBreak: Codable, Equatable, Identifiable {
    let id: UUID
    let type: BreakType
    let startedAt: Date
    let endedAt: Date
    let windAtStart: Double
    let windDecreased: Double
    let wasViolated: Bool

    var durationMinutes: Double {
        endedAt.timeIntervalSince(startedAt) / 60
    }

    init(
        id: UUID = UUID(),
        type: BreakType,
        startedAt: Date,
        endedAt: Date,
        windAtStart: Double,
        windDecreased: Double,
        wasViolated: Bool
    ) {
        self.id = id
        self.type = type
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.windAtStart = windAtStart
        self.windDecreased = windDecreased
        self.wasViolated = wasViolated
    }
}

// MARK: - Mock Data

extension DynamicPet {
    static func mock(
        name: String = "Fern",
        phase: Int = 2,
        essence: Essence? = .plant,
        windPoints: Double = 45,
        totalDays: Int = 14
    ) -> DynamicPet {
        let petId = UUID()

        return DynamicPet(
            id: petId,
            name: name,
            evolutionHistory: .mock(phase: phase, essence: essence, totalDays: totalDays),
            purpose: "Social Media",
            windPoints: windPoints,
            dailyStats: DailyUsageStat.mockList(petId: petId, days: totalDays),
            limitedSources: LimitedSource.mockList(days: totalDays)
        )
    }

    static func mockWithBreak() -> DynamicPet {
        let pet = mock(windPoints: 65)
        pet.activeBreak = .mock(type: .committed, minutesAgo: 10, durationMinutes: 30)
        return pet
    }

    static func mockBlob(
        name: String = "Blobby",
        canUseEssence: Bool = false,
        windPoints: Double = 20
    ) -> DynamicPet {
        let totalDays = canUseEssence ? 2 : 0
        return mock(
            name: name,
            phase: 0,
            essence: nil,
            windPoints: windPoints,
            totalDays: totalDays
        )
    }
}
