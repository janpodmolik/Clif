import SwiftUI

/// Wind intensity levels determined by blocked app usage time.
enum WindLevel: Int, CaseIterable {
    case none = 0
    case low = 1
    case medium = 2
    case high = 3

    var displayName: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var icon: String {
        switch self {
        case .none: return "sun.max.fill"
        case .low: return "wind"
        case .medium: return "wind"
        case .high: return "tornado"
        }
    }

    var label: String {
        switch self {
        case .none: return "Klid"
        case .low: return "Mírný"
        case .medium: return "Střední"
        case .high: return "Silný"
        }
    }

    var color: Color {
        switch self {
        case .none: return .yellow
        case .low: return .green
        case .medium: return .orange
        case .high: return .red
        }
    }
}
