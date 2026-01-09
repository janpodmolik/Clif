import Foundation

/// Types of evolution transition effects available.
/// Both effects use Metal shaders for smooth GPU-accelerated animations.
enum EvolutionTransitionType: Int, CaseIterable {
    case dissolve = 1
    case glowBurst = 2

    var displayName: String {
        switch self {
        case .dissolve: return "Dissolve"
        case .glowBurst: return "Glow Burst"
        }
    }

    /// Default duration for this transition type.
    var defaultDuration: TimeInterval {
        switch self {
        case .dissolve: return 1.5
        case .glowBurst: return 2.0
        }
    }

    /// Progress point (0-1) when asset swap should occur (new image starts appearing).
    var assetSwapPoint: CGFloat {
        switch self {
        case .dissolve: return 0.45  // Overlap with old image dissolving
        case .glowBurst: return 0.58  // Middle of flash (0.55 + 0.1/2)
        }
    }

    /// Progress point (0-1) when old image should be hidden completely.
    var oldImageHidePoint: CGFloat {
        switch self {
        case .dissolve: return 0.60  // Old fully dissolved by shader at 0.55
        case .glowBurst: return 0.60  // Shortly after flash starts
        }
    }
}
