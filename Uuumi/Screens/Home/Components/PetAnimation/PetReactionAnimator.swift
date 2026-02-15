import Foundation

@Observable
final class PetReactionAnimator {
    private(set) var trigger: Int = 0
    private(set) var pending: PetReactionType? = nil
    private(set) var pendingGlow = false
    private var lastPlayTime: Date = .distantPast

    /// Matches the shader's hard cutoff in `calculateTapOffset` (1.0s).
    private static let cooldown: TimeInterval = 1.0

    /// Request a reaction animation. Ignored if the previous one hasn't finished yet.
    func play(_ type: PetReactionType, withGlow: Bool = false) {
        guard type != .none,
              Date().timeIntervalSince(lastPlayTime) >= Self.cooldown else { return }
        pending = type
        pendingGlow = withGlow
        lastPlayTime = Date()
        trigger += 1
    }

    /// Request a random reaction animation (any type except `.none`).
    func playRandom(withGlow: Bool = false) {
        guard let type = PetReactionType.allCases.filter({ $0 != .none }).randomElement() else { return }
        play(type, withGlow: withGlow)
    }

    /// Called by IslandView to consume the pending animation request.
    func consume() -> (type: PetReactionType, glow: Bool)? {
        guard let type = pending else { return nil }
        let glow = pendingGlow
        pending = nil
        pendingGlow = false
        return (type, glow)
    }
}
