import Foundation

/// Types of breaks available.
/// Free breaks have no penalty, committed breaks blow away the pet if ended early.
enum BreakType: String, Codable, CaseIterable {
    case free
    case committed
    case safety

    /// Break types that can be manually selected by the user.
    /// Safety shield is auto-activated only and not user-selectable.
    static var selectableCases: [BreakType] {
        [.free, .committed]
    }

    /// Display name for UI.
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .committed: return "Committed"
        case .safety: return "Safety Shield"
        }
    }

    /// Description of what happens if break is violated.
    var penaltyDescription: String {
        switch self {
        case .free: return "No penalty"
        case .committed: return "Pet blows away"
        case .safety: return "Auto-activated protection"
        }
    }

    /// Icon for UI display.
    var icon: String {
        switch self {
        case .free: return "leaf.fill"
        case .committed: return "flame.fill"
        case .safety: return "shield.fill"
        }
    }
}
