import Foundation

/// The base blob evolution - a single form with no phases.
enum BlobEvolution: CaseIterable, EvolutionType {
    case blob

    static let evolutionId = "blob"
    static let displayName = "Blob"

    var assetName: String { "blob" }

    var displayScale: CGFloat { 1.0 }

    func assetName(for mood: Mood) -> String {
        "blob/\(mood.rawValue)/1"
    }

    func windConfig(for level: WindLevel) -> WindConfig {
        switch level {
        case .none:
            return .none
        case .low:
            return WindConfig(
                intensity: 0.3,
                bendCurve: 3.0,
                swayAmount: 0.1,
                rotationAmount: 0.2
            )
        case .medium:
            return WindConfig(
                intensity: 0.6,
                bendCurve: 2.8,
                swayAmount: 0.3,
                rotationAmount: 0.4
            )
        case .high:
            return WindConfig(
                intensity: 1.0,
                bendCurve: 2.5,
                swayAmount: 0.5,
                rotationAmount: 0.6
            )
        }
    }
}
