import SwiftUI

enum BigTagPhase: Equatable {
    case idle
    case popIn
    case pause
    case flyToTab
    case arrived
}

@Observable
final class CoinsRewardAnimator {

    // MARK: - State

    private(set) var isAnimating = false
    private(set) var amount = 0
    private(set) var isPulsingTab = false
    private(set) var phase: BigTagPhase = .idle

    // MARK: - API

    func showReward(_ coins: Int) {
        guard coins > 0, !isAnimating else { return }
        amount = coins
        isAnimating = true

        runBigTagAnimation()
    }

    // MARK: - Big Tag Animation

    private func runBigTagAnimation() {
        phase = .idle

        let popInDuration: Double = 0.35
        let holdDuration: Double = 0.95
        let flyDuration: Double = 0.5
        let arriveDuration: Double = 0.15
        let pulseHoldDuration: Double = 0.4

        var elapsed: Double = 0

        // Phase 1: Pop in at large scale
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            withAnimation(.spring(duration: popInDuration, bounce: 0.4)) {
                self.phase = .popIn
            }
        }
        elapsed += popInDuration

        // Phase 2: Hold for visibility
        DispatchQueue.main.asyncAfter(deadline: .now() + elapsed) { [weak self] in
            self?.phase = .pause
        }
        elapsed += holdDuration

        // Phase 3: Fly to tab
        let flyStart = elapsed
        DispatchQueue.main.asyncAfter(deadline: .now() + flyStart) { [weak self] in
            guard let self else { return }
            withAnimation(.easeInOut(duration: flyDuration)) {
                self.phase = .flyToTab
            }
        }
        elapsed += flyDuration

        // Phase 4: Arrive, trigger tab pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + elapsed) { [weak self] in
            guard let self else { return }
            withAnimation(.easeOut(duration: arriveDuration)) {
                self.phase = .arrived
            }
            self.isPulsingTab = true
        }
        elapsed += arriveDuration + pulseHoldDuration

        // Phase 5: Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + elapsed) { [weak self] in
            guard let self else { return }
            self.isPulsingTab = false
            self.phase = .idle
            self.isAnimating = false
        }
    }
}
