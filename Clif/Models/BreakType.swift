import Foundation

/// Types of breaks available in Dynamic Wind mode.
/// Each type has different fall rate multipliers and penalties for breaking early.
enum BreakType: String, Codable, CaseIterable {
    case free
    case committed
    case hardcore

    /// Multiplier applied to base fallRate from DynamicWindConfig.
    /// Higher = faster wind decrease during break.
    var fallRateMultiplier: Double {
        switch self {
        case .free: return 1.0
        case .committed: return 1.25
        case .hardcore: return 1.5
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
        case .free: return "peacesign"
        case .committed: return "exclamationmark.triangle"
        case .hardcore: return "nosign"
        }
    }
}
