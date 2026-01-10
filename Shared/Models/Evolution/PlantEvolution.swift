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

    var displayScale: CGFloat {
        switch self {
        case .phase1: return 0.95
        case .phase2: return 1.01
        case .phase3: return 1.06
        case .phase4: return 1.20
        }
    }

    func assetName(for mood: Mood) -> String {
        "evolutions/plant/\(mood.rawValue)/\(rawValue)"
    }

    func windConfig(for level: WindLevel) -> WindConfig {
        let baseBend = baseBendCurve
        switch level {
        case .none:
            return .none
        case .low:
            return WindConfig(
                intensity: 0.5,
                bendCurve: baseBend,
                swayAmount: 4.9,
                rotationAmount: 1.0
            )
        case .medium:
            return WindConfig(
                intensity: 1.5,
                bendCurve: baseBend,
                swayAmount: 7.5,
                rotationAmount: 0.8
            )
        case .high:
            return WindConfig(
                intensity: 2.0,
                bendCurve: baseBend + 0.5,
                swayAmount: 11.0,
                rotationAmount: 0.8
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
