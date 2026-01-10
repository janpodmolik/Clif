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
        case .phase2: return 1.05
        case .phase3: return 1.12
        case .phase4: return 1.40
        }
    }

    func assetName(for mood: Mood) -> String {
        let moodFolder = mood == .blown ? Mood.sad.rawValue : mood.rawValue
        return "evolutions/plant/\(moodFolder)/\(rawValue)"
    }

    func windConfig(for level: WindLevel) -> WindConfig {
        .default(for: level)
    }
}
