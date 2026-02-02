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
    /// Single source of truth: reads/writes directly from SharedDefaults.
    /// Only valid for the currently monitored pet (SharedDefaults.monitoredPetId == id).
    var windPoints: Double {
        get { SharedDefaults.monitoredWindPoints }
        set { SharedDefaults.monitoredWindPoints = newValue }
    }

    /// Last recorded threshold seconds from DeviceActivityMonitor.
    /// Single source of truth: reads/writes directly from SharedDefaults.
    var lastThresholdSeconds: Int {
        get { SharedDefaults.monitoredLastThresholdSeconds }
        set { SharedDefaults.monitoredLastThresholdSeconds = newValue }
    }

    /// Currently active break session, if any.
    /// Computed from SharedDefaults - single source of truth for shield/break state.
    var activeBreak: ActiveBreak? {
        guard SharedDefaults.isShieldActive,
              let activatedAt = SharedDefaults.shieldActivatedAt,
              let type = SharedDefaults.activeBreakType else {
            return nil
        }

        let duration: TimeInterval? = SharedDefaults.committedBreakDuration.map {
            $0 == 0 ? TimeInterval(20) : TimeInterval($0 * 60)
        }

        return ActiveBreak(
            type: type,
            startedAt: activatedAt,
            plannedDuration: duration
        )
    }

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

    /// Effective wind points accounting for real-time shield recovery.
    /// When shield is active, wind decreases over time based on fallRate.
    var effectiveWindPoints: Double {
        guard SharedDefaults.isShieldActive else {
            return windPoints
        }
        return SharedDefaults.effectiveWind
    }

    /// Wind progress for UI (0+), not capped at 1.0.
    /// Uses effectiveWindPoints to show real-time decrease during active shield.
    var windProgress: CGFloat {
        CGFloat(max(effectiveWindPoints / 100.0, 0))
    }

    /// Whether pet has been blown away.
    /// Delegates to evolutionHistory.isBlown — persistent and explicit.
    var isBlownAway: Bool {
        isBlown
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

    /// Updates wind based on new threshold seconds from monitor.
    func updateWind(newThresholdSeconds: Int) {
        let deltaSeconds = newThresholdSeconds - lastThresholdSeconds
        guard deltaSeconds > 0 else { return }

        // riseRate is now per second
        let riseRatePerSecond = preset.riseRate / 60.0
        windPoints += Double(deltaSeconds) * riseRatePerSecond
        lastThresholdSeconds = newThresholdSeconds

        // Keep SharedDefaults in sync for extension snapshots
        SnapshotLogging.updateWindPoints(windPoints)
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
    func blowAway(reason: BlowAwayReason = .limitExceeded) {
        guard !isBlown else { return }
        evolutionHistory.markAsBlown()

        // Log snapshot
        SnapshotLogging.logBlowAway(
            petId: id,
            windPoints: windPoints,
            reason: reason
        )
    }

    /// Resets wind to 0 (for daily reset).
    func resetWind() {
        windPoints = 0
        lastThresholdSeconds = 0
    }

    /// Checks if pet was blown away (from snapshots) and updates state.
    /// Call on app foreground to catch blow-away events from extension.
    func checkBlowAwayState() {
        guard SharedDefaults.monitoredPetId == id else { return }

        // Snapshots from extension — pet was blown away in background
        if SnapshotStore.shared.wasBlownAwayToday(petId: id) && !isBlownAway {
            blowAway()
            return
        }

        // Safety shield protects against auto-blow-away
        if SharedDefaults.activeBreakType == .safety {
            return
        }
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        name: String,
        evolutionHistory: EvolutionHistory,
        purpose: String?,
        preset: WindPreset = .default,
        dailyStats: [DailyUsageStat] = [],
        limitedSources: [LimitedSource] = [],
        breakHistory: [CompletedBreak] = []
    ) {
        self.id = id
        self.name = name
        self.evolutionHistory = evolutionHistory
        self.purpose = purpose
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
            (.free, 240, 25, 70, false),
            (.committed, 360, 8, 35, false),
            (.free, 480, 15, 60, false),
            (.committed, 600, 30, 85, false),
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

#if DEBUG
// MARK: - Debug Helpers

extension Pet {
    /// Shifts createdAt back by one day, making the pet appear one day older.
    func debugBumpDay() {
        evolutionHistory.debugBumpDay()
    }

    /// Force-unlocks essence usage (shifts createdAt so daysSinceCreation >= 1).
    func debugUnlockEssence() {
        guard isBlob, !canUseEssence else { return }
        while !canUseEssence {
            evolutionHistory.debugBumpDay()
        }
    }

    /// Force-unlocks next evolution (clears daily lock and shifts createdAt so daysUntilEvolution == 0).
    func debugUnlockEvolution() {
        guard !isBlob, !isBlown, currentPhase < evolutionHistory.maxPhase else { return }
        if evolutionHistory.hasProgressedToday {
            evolutionHistory.debugClearDailyProgress()
        }
        while daysUntilEvolution ?? 0 > 0 {
            evolutionHistory.debugBumpDay()
        }
    }

    /// Clears the daily evolution gate for testing.
    func debugClearDailyProgress() {
        evolutionHistory.debugClearDailyProgress()
    }

    /// Resets pet back to blob state.
    func debugResetToBlob() {
        evolutionHistory.debugResetToBlob()
    }
}
#endif

// MARK: - Mock Data

extension Pet {
    /// Sets up SharedDefaults for mock pet display.
    /// Call this before creating mock pets to ensure windPoints reads correct values.
    static func setupMockDefaults(petId: UUID, windPoints: Double, lastThresholdSeconds: Int = 0) {
        SharedDefaults.monitoredPetId = petId
        SharedDefaults.monitoredWindPoints = windPoints
        SharedDefaults.monitoredLastThresholdSeconds = lastThresholdSeconds
    }

    static func mock(
        name: String = "Fern",
        phase: Int = 2,
        essence: Essence? = .plant,
        windPoints: Double = 0,
        totalDays: Int = 14
    ) -> Pet {
        let petId = UUID()

        // Setup SharedDefaults so computed windPoints property returns correct value
        setupMockDefaults(petId: petId, windPoints: windPoints)

        return Pet(
            id: petId,
            name: name,
            evolutionHistory: .mock(phase: phase, essence: essence, totalDays: totalDays),
            purpose: "Social Media",
            dailyStats: DailyUsageStat.mockList(petId: petId, days: totalDays),
            limitedSources: LimitedSource.mockList(),
            breakHistory: totalDays > 3 ? CompletedBreak.mockList(count: min(totalDays, 8)) : []
        )
    }

    static func mockWithBreak() -> Pet {
        // Setup SharedDefaults for break state (activeBreak is computed from these)
        // activeBreakType setter syncs isShieldActive automatically
        SharedDefaults.shieldActivatedAt = Date().addingTimeInterval(-10 * 60) // 10 minutes ago
        SharedDefaults.activeBreakType = .committed
        SharedDefaults.committedBreakDuration = 30

        return mock(windPoints: 65)
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

    static func mockBlown(
        name: String = "Fern",
        phase: Int = 3
    ) -> Pet {
        let petId = UUID()
        setupMockDefaults(petId: petId, windPoints: 100)

        return Pet(
            id: petId,
            name: name,
            evolutionHistory: .mock(phase: phase, essence: .plant, totalDays: 10, isBlown: true),
            purpose: "Social Media",
            dailyStats: DailyUsageStat.mockList(petId: petId, days: 10),
            limitedSources: LimitedSource.mockList(),
            breakHistory: CompletedBreak.mockList(count: 5)
        )
    }
}
