import Foundation

enum CommittedBreakMode: Codable, Equatable {
    case timed(minutes: Int)
    case untilZeroWind
    case untilEndOfDay
    #if DEBUG
    case debug
    #endif

    /// Duration in seconds for timed modes, nil for open-ended modes.
    var durationSeconds: TimeInterval? {
        switch self {
        case .timed(let minutes): TimeInterval(minutes * 60)
        case .untilZeroWind, .untilEndOfDay: nil
        #if DEBUG
        case .debug: 20
        #endif
        }
    }

    /// Actual break duration in minutes for coin reward calculation.
    /// For timed/debug modes, uses the planned duration.
    /// For open-ended modes, calculates when the break condition was actually met
    /// (not wall-clock time, which inflates when the app was backgrounded past completion).
    func coinMinutes(startedAt: Date, windPoints: Double, fallRate: Double) -> Int {
        switch self {
        case .timed(let minutes):
            return minutes
        #if DEBUG
        case .debug:
            return 0
        #endif
        case .untilZeroWind:
            guard fallRate > 0 else { return 0 }
            let actualSeconds = windPoints / fallRate
            return min(Int(actualSeconds / 60), 24 * 60)
        case .untilEndOfDay:
            guard let midnight = Calendar.current.nextDate(
                after: startedAt,
                matching: DateComponents(hour: 0, minute: 0),
                matchingPolicy: .nextTime
            ) else { return 0 }
            let actualSeconds = midnight.timeIntervalSince(startedAt)
            return min(Int(actualSeconds / 60), 24 * 60)
        }
    }
}
