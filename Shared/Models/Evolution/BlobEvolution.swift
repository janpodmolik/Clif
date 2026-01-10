import SwiftUI

/// The base blob evolution - a single form with no phases.
enum BlobEvolution: CaseIterable, EvolutionType {
    case blob

    static let evolutionId = "blob"
    static let displayName = "Blob"
    static let themeColor: Color = .white

    var assetName: String { "blob" }

    var displayScale: CGFloat { 0.75 }

    func assetName(for mood: Mood) -> String {
        "blob/\(mood.forAsset.rawValue)/1"
    }

    func windConfig(for level: WindLevel) -> WindConfig {
        .default(for: level)
    }
}
