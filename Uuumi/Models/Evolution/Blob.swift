import Foundation

/// The base blob - the origin state before evolution.
struct Blob: Hashable {
    static let shared = Blob()

    let displayScale: CGFloat = 0.75
    let idleConfig: IdleConfig = .default

    func assetName(for windLevel: WindLevel) -> String {
        "blob/\(windLevel.assetFolder)/1"
    }

    func assetName(for windLevel: WindLevel, isBlownAway: Bool) -> String {
        let folder = isBlownAway ? WindLevel.blownAssetFolder : windLevel.assetFolder
        return "blob/\(folder)/1"
    }

    func reactionConfig(for type: PetReactionType) -> ReactionConfig {
        .default(for: type)
    }
}
