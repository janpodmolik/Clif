import Foundation

/// Types of breaks available in Dynamic Wind mode.
/// Each type has different wind decrease rates and penalties for breaking early.
enum BreakType: String, Codable, CaseIterable {
    case free
    case committed
    case hardcore

    /// Wind points decreased per minute during this break type.
    var decreaseRate: Double {
        switch self {
        case .free: return 0.3
        case .committed: return 0.6
        case .hardcore: return 1.0
        }
    }

    /// Display name for UI.
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .committed: return "Committed"
        case .hardcore: return "Hardcore"
        }
    }

    /// Description of what happens if break is violated.
    var penaltyDescription: String {
        switch self {
        case .free: return "No penalty"
        case .committed: return "Wind won't decrease"
        case .hardcore: return "Pet blows away"
        }
    }

    /// Icon for UI display.
    var icon: String {
        switch self {
        case .free: return "leaf"
        case .committed: return "hand.raised"
        case .hardcore: return "flame"
        }
    }
}
