import SwiftUI

@Observable
final class CoinsRewardAnimator {
    private(set) var isShowingTag = false
    private(set) var isSlidingDown = false
    private(set) var amount = 0
    private(set) var isPulsingTab = false

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

        // Phase 4: Tab pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.isPulsingTab = true
        }

        // Phase 5: End pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            self?.isPulsingTab = false
            self?.isSlidingDown = false
        }
    }
}
