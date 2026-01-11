import Foundation

/// The base blob - the origin state before evolution.
struct Blob: Hashable {
    static let shared = Blob()

    let displayScale: CGFloat = 0.75
    let idleConfig: IdleConfig = .default

    func assetName(for mood: Mood) -> String {
        "blob/\(mood.forAsset.rawValue)/1"
    }

    /// Convenience method to get asset name from wind level.
    func assetName(for windLevel: WindLevel) -> String {
        assetName(for: Mood(from: windLevel))
    }

    func windConfig(for level: WindLevel) -> WindConfig {
        .default(for: level)
    }

    func tapConfig(for type: TapAnimationType) -> TapConfig {
        .default(for: type)
    }
}
