import SwiftUI

@Observable
final class BlowAwayAnimator {
    // MARK: - Animation Transform

    private(set) var offsetX: CGFloat = 0
    private(set) var rotation: CGFloat = 0

    // MARK: - State

    private(set) var isAnimating: Bool = false
    private(set) var windBurstActive: Bool = false

    /// Controls visibility of the camera/VHS replay overlay.
    private(set) var replayOverlayVisible: Bool = false

    /// Whether the pet is currently off its resting position (animating or already blown).
    var isBlowingAway: Bool { offsetX != 0 }

    /// Set when blow away is triggered from PetDetailScreen — animation plays after dismiss.
    var pendingBlowAway: Bool = false

    // MARK: - API

    /// Sets the pet to already-blown position (off-screen, no animation).
    /// Use when pet was blown in background and app returns to foreground.
    func setBlownState(screenWidth: CGFloat) {
        offsetX = screenWidth + 150
        rotation = BlowAwayConfig.default.rotationDegrees
    }

    /// Resets to on-screen position without animation.
    func reset() {
        offsetX = 0
        rotation = 0
        isAnimating = false
        windBurstActive = false
        replayOverlayVisible = false
    }

    /// Triggers the blow away animation — pet tilts and flies off-screen.
    func trigger(screenWidth: CGFloat) {
        let config = BlowAwayConfig.default
        windBurstActive = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isAnimating = true
            withAnimation(.easeIn(duration: config.duration)) {
                self.offsetX = screenWidth + 150
                self.rotation = config.rotationDegrees
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + config.duration + 0.4) {
            self.windBurstActive = false
            self.isAnimating = false
        }
    }

    /// Cinematic replay: rewind back to island, pause, then slow-motion blow away.
    func replay(screenWidth: CGFloat) {
        guard !isAnimating else { return }

        let config = BlowAwayConfig.default
        let slowmo = BlowAwayConfig.slowmo
        let rewindDuration = BlowAwayConfig.rewindDuration
        let pause = BlowAwayConfig.rewindPause

        isAnimating = true
        replayOverlayVisible = true

        // Ensure pet starts in blown position (off-screen)
        offsetX = screenWidth + 150
        rotation = config.rotationDegrees

        // --- Phase 1: Rewind (fly back to island) ---
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: rewindDuration)) {
                self.offsetX = 0
                self.rotation = 0
            }
        }

        // --- Phase 2: Slow-motion blow away ---
        let phase2Start = 0.05 + rewindDuration + pause

        DispatchQueue.main.asyncAfter(deadline: .now() + phase2Start) {
            self.windBurstActive = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + phase2Start + 0.1) {
            withAnimation(.easeIn(duration: slowmo.duration)) {
                self.offsetX = screenWidth + 150
                self.rotation = slowmo.rotationDegrees
            }
        }

        // --- Cleanup ---
        let totalDuration = phase2Start + 0.1 + slowmo.duration

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.3) {
            self.windBurstActive = false
            self.replayOverlayVisible = false
        }

        // Keep isAnimating true until overlay fade-out completes (~0.3s)
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.6) {
            self.isAnimating = false
        }
    }
}
