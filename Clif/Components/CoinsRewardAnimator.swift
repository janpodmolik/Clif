import SwiftUI

@Observable
final class CoinsRewardAnimator {
    private(set) var isShowingTag = false
    private(set) var isSlidingDown = false
    private(set) var amount = 0
    private(set) var tabPulseScale: CGFloat = 1.0
    private(set) var tabPulseOpacity: Double = 0

    func showReward(_ coins: Int) {
        guard coins > 0, !isShowingTag else { return }
        amount = coins

        // Phase 1: Quick pop in
        withAnimation(.spring(duration: 0.25, bounce: 0.4)) {
            isShowingTag = true
        }

        // Phase 2: Slide down into tab (after pause)
        withAnimation(.easeIn(duration: 0.3).delay(1.0)) {
            isSlidingDown = true
        }

        // Phase 3: Fade out as it "enters" the tab
        withAnimation(.easeIn(duration: 0.15).delay(1.15)) {
            isShowingTag = false
        }

        // Phase 4: Tab icon pulse - appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.tabPulseScale = 1.0
            withAnimation(.easeOut(duration: 0.15)) {
                self?.tabPulseOpacity = 1.0
            }

            // Phase 5: Scale up
            withAnimation(.easeOut(duration: 0.15).delay(0.05)) {
                self?.tabPulseScale = 1.2
            }

            // Phase 6: Scale down and fade out
            withAnimation(.easeInOut(duration: 0.25).delay(0.2)) {
                self?.tabPulseScale = 1.0
                self?.tabPulseOpacity = 0
            }
        }

        // Reset sliding state for next animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { [weak self] in
            self?.isSlidingDown = false
        }
    }
}
