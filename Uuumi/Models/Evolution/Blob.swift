import Foundation

/// The base blob - the origin state before evolution.
struct Blob: Hashable {
    static let shared = Blob()

    let displayScale: CGFloat = 0.75
    let idleConfig: IdleConfig = .default

    func bodyAssetName(for windLevel: WindLevel) -> String {
        "blob/1/body"
    }

    func eyesAssetName(for windLevel: WindLevel) -> String {
        "blob/1/eyes/\(windLevel.eyes)"
    }

    func eyesAssetName(for windLevel: WindLevel, isBlownAway: Bool) -> String {
        let eyes = isBlownAway ? WindLevel.blownEyes : windLevel.eyes
        return "blob/1/eyes/\(eyes)"
    }

    func scaredEyesAssetName(for windLevel: WindLevel) -> String? {
        "blob/1/eyes/scared"
    }

    func reactionConfig(for type: PetReactionType) -> ReactionConfig {
        .default(for: type)
    }
}
