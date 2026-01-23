import FamilyControls
import Foundation
import ManagedSettings

@Observable
final class Pet: Identifiable, PetPresentable, PetWithSources {
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
    let preset: WindPreset

    // MARK: - PetWithSources

    var dailyStats: [DailyUsageStat]
    var limitedSources: [LimitedSource]

    /// Break history for current session.
    var breakHistory: [CompletedBreak]

    /// Full usage stats for history display.
    var fullStats: FullUsageStats {
        FullUsageStats(days: dailyStats)
    }

    // MARK: - Wind Progress

    /// Wind progress for UI (0-1), clamped.
    var windProgress: CGFloat {
        CGFloat(min(max(windPoints / 100.0, 0), 1.0))
    }

    /// Whether pet has been blown away.
    var isBlownAway: Bool {
        windPoints >= 100
    }

    /// Whether pet is currently on a break.
    var isOnBreak: Bool {
        activeBreak != nil
    }

    /// Whether evolution is available for this pet.
    var isEvolutionAvailable: Bool {
        isBlob ? canUseEssence : canEvolve
    }

    /// Days until next milestone (essence or evolution).
    var daysUntilNextMilestone: Int? {
        if isBlob {
            return daysUntilEssence
        } else {
            return daysUntilEvolution
        }
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

        windPoints += Double(deltaMinutes) * preset.riseRate
        windPoints = min(windPoints, 100)
        lastThresholdMinutes = newThresholdMinutes

        // Keep SharedDefaults in sync for extension snapshots
        SnapshotLogging.updateWindPoints(windPoints)

        if windPoints >= 100 {
            blowAway()
        }
    }

    /// Starts a new break session.
    func startBreak(_ breakSession: ActiveBreak) {
        activeBreak = breakSession

        // Log snapshot
        let breakTypePayload = breakSession.toSnapshotPayload()
        SnapshotLogging.logBreakStarted(
            petId: id,
            windPoints: windPoints,
            breakType: breakTypePayload
        )
    }

    /// Ends current break successfully, applying wind decrease.
    func endBreak() {
        guard let breakSession = activeBreak else { return }

        let actualMinutes = Int(breakSession.elapsedMinutes)
        let decreased = breakSession.windDecreased(for: preset)
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

        // Log snapshot
        SnapshotLogging.logBreakEnded(
            petId: id,
            windPoints: windPoints,
            actualMinutes: actualMinutes
        )
    }

    /// Fails current break (user violated it).
    func failBreak() {
        guard let breakSession = activeBreak else { return }

        let actualMinutes = Int(breakSession.elapsedMinutes)
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

        // Log snapshot
        SnapshotLogging.logBreakFailed(
            petId: id,
            windPoints: windPoints,
            actualMinutes: actualMinutes
        )
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

        // Log snapshot
        SnapshotLogging.logBlowAway(
            petId: id,
            windPoints: windPoints
        )
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
        preset: WindPreset = .default,
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
        self.preset = preset
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

// MARK: - CompletedBreak Mock Data

extension CompletedBreak {
    static func mock(
        type: BreakType = .committed,
        minutesAgo: Int = 60,
        durationMinutes: Double = 15,
        windAtStart: Double = 50,
        windDecreased: Double = 12,
        wasViolated: Bool = false
    ) -> CompletedBreak {
        let endedAt = Date().addingTimeInterval(-Double(minutesAgo) * 60)
        let startedAt = endedAt.addingTimeInterval(-durationMinutes * 60)

        return CompletedBreak(
            type: type,
            startedAt: startedAt,
            endedAt: endedAt,
            windAtStart: windAtStart,
            windDecreased: wasViolated ? 0 : windDecreased,
            wasViolated: wasViolated
        )
    }

    static func mockList(count: Int = 8) -> [CompletedBreak] {
        let configs: [(BreakType, Int, Double, Double, Bool)] = [
            (.free, 30, 10, 40, false),
            (.committed, 120, 20, 55, false),
            (.hardcore, 240, 25, 70, false),
            (.free, 360, 8, 35, false),
            (.committed, 480, 15, 60, true),
            (.hardcore, 600, 30, 85, false),
            (.free, 720, 12, 45, false),
            (.committed, 840, 18, 50, false),
        ]

        return configs.prefix(count).map { type, minutesAgo, duration, wind, violated in
            mock(
                type: type,
                minutesAgo: minutesAgo,
                durationMinutes: duration,
                windAtStart: wind,
                windDecreased: duration * 0.8,
                wasViolated: violated
            )
        }
    }
}

// MARK: - Mock Data

extension Pet {
    static func mock(
        name: String = "Fern",
        phase: Int = 2,
        essence: Essence? = .plant,
        windPoints: Double = 45,
        totalDays: Int = 14
    ) -> Pet {
        let petId = UUID()

        return Pet(
            id: petId,
            name: name,
            evolutionHistory: .mock(phase: phase, essence: essence, totalDays: totalDays),
            purpose: "Social Media",
            windPoints: windPoints,
            dailyStats: DailyUsageStat.mockList(petId: petId, days: totalDays),
            limitedSources: LimitedSource.mockList(days: totalDays),
            breakHistory: totalDays > 3 ? CompletedBreak.mockList(count: min(totalDays, 8)) : []
        )
    }

    static func mockWithBreak() -> Pet {
        let pet = mock(windPoints: 65)
        pet.activeBreak = .mock(type: .committed, minutesAgo: 10, durationMinutes: 30)
        return pet
    }

    static func mockWithBreakHistory() -> Pet {
        let pet = mock(windPoints: 45, totalDays: 10)
        return pet
    }

    static func mockBlob(
        name: String = "Blobby",
        canUseEssence: Bool = false,
        windPoints: Double = 20
    ) -> Pet {
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
