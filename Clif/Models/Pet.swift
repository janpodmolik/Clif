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

    /// Effective wind points accounting for real-time shield recovery.
    /// When shield is active, wind decreases over time based on fallRate.
    var effectiveWindPoints: Double {
        guard SharedDefaults.isShieldActive,
              let activatedAt = SharedDefaults.shieldActivatedAt else {
            return windPoints
        }

        let elapsedSeconds = Date().timeIntervalSince(activatedAt)
        let fallRate = SharedDefaults.monitoredFallRate
        let decrease = elapsedSeconds * fallRate
        return max(0, windPoints - decrease)
    }

    /// Wind progress for UI (0-1), clamped.
    /// Uses effectiveWindPoints to show real-time decrease during active shield.
    var windProgress: CGFloat {
        CGFloat(min(max(effectiveWindPoints / 100.0, 0), 1.0))
    }

    /// Whether pet has been blown away.
    /// Uses stored windPoints (not effective) since blow-away is a permanent state.
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

    /// Updates wind based on new threshold seconds from monitor.
    func updateWind(newThresholdSeconds: Int) {
        let deltaSeconds = newThresholdSeconds - lastThresholdSeconds
        guard deltaSeconds > 0 else { return }

        // riseRate is now per second
        let riseRatePerSecond = preset.riseRate / 60.0
        windPoints += Double(deltaSeconds) * riseRatePerSecond
        windPoints = min(windPoints, 100)
        lastThresholdSeconds = newThresholdSeconds

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
            actualMinutes: actualMinutes,
            success: true
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

        // Committed penalty: pet blows away
        if breakSession.type == .committed {
            windPoints = 100
            blowAway()
        }
        // Free: no wind decrease (windDecreased already set to 0)

        activeBreak = nil

        // Log snapshot
        SnapshotLogging.logBreakEnded(
            petId: id,
            windPoints: windPoints,
            actualMinutes: actualMinutes,
            success: false
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
        lastThresholdSeconds = 0
    }

    /// Checks if pet was blown away (from snapshots) and updates state.
    /// Call on app foreground to catch blow-away events from extension.
    func checkBlowAwayState() {
        guard SharedDefaults.monitoredPetId == id else { return }

        if SnapshotStore.shared.wasBlownAwayToday(petId: id) && !isBlownAway {
            blowAway()
        } else if windPoints >= 100 && !isBlownAway {
            blowAway()
        }
    }

    // MARK: - Init

    init(
        id: UUID = UUID(),
        name: String,
        evolutionHistory: EvolutionHistory,
        purpose: String?,
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
        windPoints: Double = 45,
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
        mock(windPoints: 45, totalDays: 10)
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
