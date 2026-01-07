import Foundation

/// Represents the emotional state of a pet, determined by wind level.
enum Mood: String, CaseIterable {
    case happy
    case neutral
    case sad

    init(from windLevel: WindLevel) {
        switch windLevel {
        case .none, .low: self = .happy
        case .medium: self = .neutral
        case .high: self = .sad
        }
    }
}
