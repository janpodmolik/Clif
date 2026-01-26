import SwiftUI

/// Types of breaks available.
/// Free breaks have no penalty, committed breaks blow away the pet if ended early.
enum BreakType: String, Codable, CaseIterable {
    case free
    case committed

    /// Display name for UI.
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .committed: return "Committed"
        }
    }

    /// Description of what happens if break is violated.
    var penaltyDescription: String {
        switch self {
        case .free: return "No penalty"
        case .committed: return "Pet blows away"
        }
    }

    /// Icon for UI display.
    var icon: String {
        switch self {
        case .free: return "leaf.fill"
        case .committed: return "flame.fill"
        }
    }

    /// Color for UI display.
    var color: Color {
        switch self {
        case .free: return .green
        case .committed: return .orange
        }
    }
}
