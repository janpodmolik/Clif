import Foundation

/// Represents an active break session.
/// Tracks when user is taking a break from blocked apps to decrease wind.
struct ActiveBreak: Codable, Equatable {
    let id: UUID
    let type: BreakType
    let startedAt: Date
    let plannedDuration: TimeInterval?

    /// Creates a new active break.
    /// - Parameters:
    ///   - type: The break type (free/committed)
    ///   - plannedDuration: Optional duration in seconds. Nil for unlimited (free only).
    init(
        id: UUID = UUID(),
        type: BreakType,
        startedAt: Date = Date(),
        plannedDuration: TimeInterval? = nil
    ) {
        self.id = id
        self.type = type
        self.startedAt = startedAt
        self.plannedDuration = plannedDuration
    }

    /// Minutes elapsed since break started.
    var elapsedMinutes: Double {
        Date().timeIntervalSince(startedAt) / 60
    }

    /// Calculates wind decrease based on preset's fallRate and elapsed time.
    func windDecreased(for preset: WindPreset) -> Double {
        elapsedMinutes * preset.fallRate
    }

    /// Calculates predicted wind decrease for full planned duration.
    /// Returns nil if no planned duration is set.
    func predictedWindDecrease(for preset: WindPreset) -> Double? {
        guard let duration = plannedDuration else { return nil }
        let plannedMinutes = duration / 60
        return plannedMinutes * preset.fallRate
    }

    /// Remaining time in seconds, if duration is set.
    var remainingSeconds: TimeInterval? {
        guard let duration = plannedDuration else { return nil }
        let remaining = duration - Date().timeIntervalSince(startedAt)
        return max(remaining, 0)
    }

    /// Progress from 0 to 1 based on elapsed time vs planned duration.
    var progress: Double? {
        guard let duration = plannedDuration, duration > 0 else { return nil }
        let elapsed = Date().timeIntervalSince(startedAt)
        return min(elapsed / duration, 1.0)
    }

    /// Whether the planned duration has been completed.
    var isCompleted: Bool {
        guard let remaining = remainingSeconds else { return false }
        return remaining <= 0
    }
}

// MARK: - Preset Durations

extension ActiveBreak {
    /// Available break durations in minutes.
    static let availableDurations: [Int] = [15, 30, 60, 120]

    /// Creates a break with a preset duration.
    static func with(type: BreakType, durationMinutes: Int) -> ActiveBreak {
        ActiveBreak(
            type: type,
            plannedDuration: TimeInterval(durationMinutes * 60)
        )
    }

    /// Creates an unlimited free break.
    static func unlimitedFree() -> ActiveBreak {
        ActiveBreak(type: .free, plannedDuration: nil)
    }
}

// MARK: - Snapshot Conversion

extension ActiveBreak {
    /// Converts to BreakTypePayload for snapshot logging.
    func toSnapshotPayload() -> BreakTypePayload {
        let plannedMinutes = plannedDuration.map { Int($0 / 60) }

        switch type {
        case .free:
            return .free
        case .committed:
            return .committed(plannedMinutes: plannedMinutes ?? 0)
        }
    }
}

// MARK: - Mock

extension ActiveBreak {
    static func mock(
        type: BreakType = .committed,
        minutesAgo: Double = 5,
        durationMinutes: Int = 30
    ) -> ActiveBreak {
        ActiveBreak(
            type: type,
            startedAt: Date().addingTimeInterval(-minutesAgo * 60),
            plannedDuration: TimeInterval(durationMinutes * 60)
        )
    }
}
