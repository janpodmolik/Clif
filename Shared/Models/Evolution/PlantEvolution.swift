import Foundation

/// Plant evolution with multiple phases.
enum PlantEvolution: Int, CaseIterable, EvolutionType {
    case phase1 = 1
    case phase2 = 2
    case phase3 = 3
    case phase4 = 4

    static let evolutionId = "plant"
    static let displayName = "Plant"

    var assetName: String { "plant-\(rawValue)" }

    var phaseNumber: Int { rawValue }

    func assetName(for mood: Mood) -> String {
        "plant/\(mood.rawValue)/\(rawValue)"
    }

    func windConfig(for level: WindLevel) -> WindConfig {
        let baseBend = baseBendCurve
        switch level {
        case .none:
            return .none
        case .low:
            return WindConfig(
                intensity: 0.3,
                bendCurve: baseBend,
                swayAmount: 0.1,
                rotationAmount: 0.2
            )
        case .medium:
            return WindConfig(
                intensity: 0.6,
                bendCurve: baseBend - 0.2,
                swayAmount: 0.3,
                rotationAmount: 0.4
            )
        case .high:
            return WindConfig(
                intensity: 1.0,
                bendCurve: baseBend - 0.4,
                swayAmount: 0.5,
                rotationAmount: 0.6
            )
        }
    }

    /// Base bend curve per phase - lower values = gentler bend for taller plants
    private var baseBendCurve: CGFloat {
        switch self {
        case .phase1: return 2.5
        case .phase2: return 2.2
        case .phase3: return 2.0
        case .phase4: return 1.8
        }
    }
}
