import Foundation

/// Type of particle effect for evolution transition.
enum EvolutionParticleType: String, CaseIterable {
    case radialExplosion

    var displayName: String {
        switch self {
        case .radialExplosion: return "Explosion"
        }
    }
}
