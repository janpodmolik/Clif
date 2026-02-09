import SwiftUI

struct BigTagRewardView: View {
    let animator: CoinsRewardAnimator
    let position: CGPoint

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
        ZStack {
            // Burst particles — rendered behind, animated independently
            BurstParticlesView(isBursting: phase == .burst)
                .position(position)

            // Tag capsule — fast independent fade-out so it feels like it explodes
            tagContent
                .scaleEffect(tagScale)
                .opacity(tagOpacity)
                .position(position)
                .animation(.easeOut(duration: 0.15), value: phase == .burst)
        }
    }

    private var tagContent: some View {
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
    }

    private var tagScale: CGFloat {
        switch phase {
        case .idle: 0.3
        case .popIn, .pause: 1.0
        case .burst: 1.3
        }
    }

    private var tagOpacity: Double {
        switch phase {
        case .idle: 0
        case .popIn, .pause: 1
        case .burst: 0
        }
    }

    // MARK: - Reduced Motion

    private var reducedMotionView: some View {
        CoinRewardTag(
            amount: animator.amount,
            isVisible: phase != .idle && phase != .burst,
            isSlidingDown: false
        )
        .position(position)
    }
}

// MARK: - Burst Particles

private struct BurstParticle: Identifiable {
    let id: Int
    let angle: Double
    let distance: CGFloat
    let size: CGFloat
    let colorIndex: Int
    let delay: Double
}

private struct BurstParticlesView: View {
    let isBursting: Bool

    private static let particles: [BurstParticle] = {
        let count = 60
        return (0..<count).map { i in
            let baseAngle = (Double(i) / Double(count)) * 2 * .pi
            let jitter = Double.random(in: -0.3...0.3)
            return BurstParticle(
                id: i,
                angle: baseAngle + jitter,
                distance: CGFloat.random(in: 35...170),
                size: CGFloat.random(in: 3...12),
                colorIndex: i % 4,
                delay: Double.random(in: 0...0.04)
            )
        }
    }()

    var body: some View {
        ZStack {
            ForEach(Self.particles) { particle in
                BurstParticleView(particle: particle, isBursting: isBursting)
            }
        }
    }
}

private struct BurstParticleView: View {
    let particle: BurstParticle
    let isBursting: Bool

    @State private var progress: CGFloat = 0

    private static let colors: [Color] = [
        Color("PremiumGold"),
        Color(red: 1.0, green: 0.85, blue: 0.3),
        .white,
        Color(red: 1.0, green: 0.75, blue: 0.2),
    ]

    var body: some View {
        Circle()
            .fill(Self.colors[particle.colorIndex])
            .frame(width: particle.size * (1 - progress * 0.5), height: particle.size * (1 - progress * 0.5))
            .offset(
                x: cos(particle.angle) * particle.distance * progress,
                y: sin(particle.angle) * particle.distance * progress
            )
            .opacity(progress < 0.4 ? 1.0 : 1.0 - ((progress - 0.4) / 0.6))
            .onChange(of: isBursting) { _, bursting in
                if bursting {
                    progress = 0
                    withAnimation(.easeOut(duration: 0.85).delay(particle.delay)) {
                        progress = 1
                    }
                }
            }
    }
}
