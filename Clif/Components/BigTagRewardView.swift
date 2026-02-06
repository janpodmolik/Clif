import SwiftUI

struct BigTagRewardView: View {
    let animator: CoinsRewardAnimator
    let startPosition: CGPoint
    let endPosition: CGPoint

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var phase: BigTagPhase { animator.phase }

    var body: some View {
        if phase != .idle {
            if reduceMotion {
                reducedMotionView
            } else {
                fullAnimationView
            }
        }
    }

    // MARK: - Full Animation

    private var fullAnimationView: some View {
        HStack(spacing: 6) {
            Image(systemName: "u.circle.fill")
                .font(.title2)
            Text("+\(animator.amount)")
                .font(.system(size: 18, weight: .heavy))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background {
            Capsule()
                .fill(Color("PremiumGold"))
                .shadow(color: Color("PremiumGold").opacity(0.5), radius: 8, y: 2)
        }
        .scaleEffect(scaleForPhase)
        .position(positionForPhase)
        .opacity(opacityForPhase)
    }

    private var scaleForPhase: CGFloat {
        switch phase {
        case .idle: 0.3
        case .popIn, .pause: 1.2
        case .flyToTab: 0.5
        case .arrived: 0.0
        }
    }

    private var positionForPhase: CGPoint {
        switch phase {
        case .idle, .popIn, .pause:
            startPosition
        case .flyToTab, .arrived:
            endPosition
        }
    }

    private var opacityForPhase: Double {
        switch phase {
        case .idle, .arrived: 0
        case .popIn, .pause, .flyToTab: 1
        }
    }

    // MARK: - Reduced Motion

    private var reducedMotionView: some View {
        CoinRewardTag(
            amount: animator.amount,
            isVisible: phase != .idle && phase != .arrived,
            isSlidingDown: false
        )
        .position(endPosition)
    }
}
