import SwiftUI
import UIKit

enum CoinTagPhase: Equatable {
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
    private(set) var phase: CoinTagPhase = .idle

    // MARK: - API

    func showReward(_ coins: Int) {
        guard coins > 0, !isAnimating else { return }
        amount = coins
        isAnimating = true

        runCoinTagAnimation()
    }

    /// Immediately trigger the burst animation (e.g. when the user taps the tag).
    func triggerBurst() {
        guard isAnimating, phase == .popIn || phase == .pause else { return }
        burstTask?.cancel()
        cleanupTask?.cancel()
        performBurst()
    }

    // MARK: - Coin Tag Animation

    private var burstTask: DispatchWorkItem?
    private var cleanupTask: DispatchWorkItem?

    private func runCoinTagAnimation() {
        phase = .idle

        let popInDuration: Double = 0.35
        let holdDuration: Double = 2.5
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
            guard let self, self.phase == .popIn else { return }
            self.phase = .pause
        }
        elapsed += holdDuration

        // Phase 3: Burst — tag scales up + particles fly out
        let burst = DispatchWorkItem { [weak self] in
            self?.performBurst()
        }
        burstTask = burst
        DispatchQueue.main.asyncAfter(deadline: .now() + elapsed, execute: burst)
        elapsed += burstDuration

        // Phase 4: Cleanup
        let cleanup = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.phase = .idle
            self.isAnimating = false
        }
        cleanupTask = cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + elapsed, execute: cleanup)
    }

    private func performBurst() {
        let burstDuration: Double = 1.0
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.easeOut(duration: burstDuration)) {
            self.phase = .burst
        }

        let cleanup = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.phase = .idle
            self.isAnimating = false
        }
        cleanupTask = cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + burstDuration, execute: cleanup)
    }
}
