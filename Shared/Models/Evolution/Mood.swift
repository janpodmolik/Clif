import Foundation

/// Represents the emotional state of a pet.
/// - happy, neutral, sad are determined by wind level
/// - blown is a separate state when pet is blown away (set externally, not from wind level)
enum Mood: String, CaseIterable {
    case happy
    case neutral
    case sad
    case blown

    init(from windLevel: WindLevel) {
        switch windLevel {
        case .none, .low: self = .happy
        case .medium: self = .neutral
        case .high: self = .sad
        }
    }

    /// Mood used for asset lookup - blown falls back to sad (no blown assets exist)
    var forAsset: Mood {
        self == .blown ? .sad : self
    }

    var emoji: String {
        switch self {
        case .happy: "😊"
        case .neutral: "🙂"
        case .sad: "😞"
        case .blown: "😵"
        }
    }
}
