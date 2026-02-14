import UIKit

extension PetReactionType {
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
