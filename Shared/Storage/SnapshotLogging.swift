import Foundation

/// Helper functions for logging snapshots from the main app.
/// Extensions can use SnapshotStore directly with the monitoring context from SharedDefaults.
enum SnapshotLogging {

    /// Logs a breakStarted event.
    /// Call this when user starts a break in the main app.
    static func logBreakStarted(
        petId: UUID,
        windPoints: Double,
        breakType: BreakTypePayload
    ) {
        // Update SharedDefaults for extension access
        SharedDefaults.breakStartedAt = Date()
        SharedDefaults.monitoredWindPoints = windPoints

        let event = SnapshotEvent(
            petId: petId,
            windPoints: windPoints,
            eventType: .breakStarted(type: breakType)
        )

        SnapshotStore.shared.append(event)
    }

    /// Logs a breakEnded event.
    /// Call this when break timer completes or when break is violated.
    /// - Parameters:
    ///   - petId: The pet's ID
    ///   - windPoints: Current wind points
    ///   - actualMinutes: How long the break actually lasted
    ///   - success: Whether the break completed without violation
    static func logBreakEnded(
        petId: UUID,
        windPoints: Double,
        actualMinutes: Int,
        success: Bool
    ) {
        // Clear break tracking
        SharedDefaults.breakStartedAt = nil
        SharedDefaults.monitoredWindPoints = windPoints

        let event = SnapshotEvent(
            petId: petId,
            windPoints: windPoints,
            eventType: .breakEnded(actualMinutes: actualMinutes, success: success)
        )

        SnapshotStore.shared.append(event)
    }

    /// Logs a dailyReset event.
    /// Call this at midnight rollover.
    static func logDailyReset(
        petId: UUID,
        windPoints: Double
    ) {
        let event = SnapshotEvent(
            petId: petId,
            windPoints: windPoints,
            eventType: .dailyReset
        )

        SnapshotStore.shared.append(event)
    }

    /// Logs a blowAway event.
    /// Call this when pet blows away (windPoints >= 100).
    static func logBlowAway(
        petId: UUID,
        windPoints: Double
    ) {
        let event = SnapshotEvent(
            petId: petId,
            windPoints: windPoints,
            eventType: .blowAway
        )

        SnapshotStore.shared.append(event)
    }

    /// Updates the current wind points in SharedDefaults.
    /// Call this whenever windPoints change so extension snapshots have accurate values.
    static func updateWindPoints(_ windPoints: Double) {
        SharedDefaults.monitoredWindPoints = windPoints
    }
}
