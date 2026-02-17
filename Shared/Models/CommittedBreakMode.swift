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
}
