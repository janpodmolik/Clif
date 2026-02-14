import Foundation

/// Types of pet reaction animations (wiggle, squeeze, jiggle, bounce).
enum PetReactionType: Int, CaseIterable, Hashable {
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
        case .bounce: return "Jump"
        }
    }
}
