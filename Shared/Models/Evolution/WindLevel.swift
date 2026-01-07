import Foundation

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
}
