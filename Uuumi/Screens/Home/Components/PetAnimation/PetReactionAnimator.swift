import Foundation

@Observable
final class PetReactionAnimator {
    private(set) var trigger: Int = 0
    private(set) var pending: PetReactionType? = nil
    private(set) var pendingGlow = false
    private(set) var isAnimating = false

    /// Request a reaction animation. Ignored if one is already playing.
    func play(_ type: PetReactionType, withGlow: Bool = false) {
        guard !isAnimating, type != .none else { return }
        pending = type
        pendingGlow = withGlow
        trigger += 1
    }

    /// Called by IslandView to consume the pending animation request.
    func consume() -> (type: PetReactionType, glow: Bool)? {
        guard let type = pending else { return nil }
        let glow = pendingGlow
        pending = nil
        pendingGlow = false
        isAnimating = true
        return (type, glow)
    }

    /// Called by IslandView when the animation finishes.
    func animationDidFinish() {
        isAnimating = false
    }
}
