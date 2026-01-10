import UIKit

/// Types of tap animations available for pet interaction.
enum TapAnimationType: Int, CaseIterable {
    case none = 0
    case wiggle = 1
    case squeeze = 2
    case jiggle = 3
    case bounce = 4

    var displayName: String {
        switch self {
        case .none: return "None"
        case .wiggle: return "Wiggle"
        case .squeeze: return "Squeeze"
        case .jiggle: return "Jiggle"
        case .bounce: return "Bounce"
        }
    }

    var duration: TimeInterval {
        switch self {
        case .none: return 0
        case .wiggle: return 0.4
        case .squeeze: return 0.5
        case .jiggle: return 0.7
        case .bounce: return 0.8
        }
    }

    var hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle {
        switch self {
        case .none: return .light
        case .wiggle: return .light
        case .squeeze: return .medium
        case .jiggle: return .soft
        case .bounce: return .rigid
        }
    }
}
