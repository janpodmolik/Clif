import SwiftUI
import UIKit

enum BigTagPhase: Equatable {
    case idle
    case popIn
    case pause
    case burst
}

@Observable
final class CoinsRewardAnimator {

    // MARK: - State

    private(set) var isAnimating = false
    private(set) var amount = 0
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
        let burstDuration: Double = 1.0

        var elapsed: Double = 0

        // Phase 1: Pop in at large scale
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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

        // Phase 3: Burst — tag scales up + particles fly out
        DispatchQueue.main.asyncAfter(deadline: .now() + elapsed) { [weak self] in
            guard let self else { return }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation(.easeOut(duration: burstDuration)) {
                self.phase = .burst
            }
        }
        elapsed += burstDuration

        // Phase 4: Cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + elapsed) { [weak self] in
            guard let self else { return }
            self.phase = .idle
            self.isAnimating = false
        }
    }
}
