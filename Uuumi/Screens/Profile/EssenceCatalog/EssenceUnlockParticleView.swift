import SwiftUI

/// Radial particle burst for essence unlock celebration.
/// Inspired by EvolutionParticleView but simpler and shorter.
struct EssenceUnlockParticleView: View {
    let isActive: Bool
    let color: Color

    @State private var particles: [UnlockParticle] = []
    @State private var startTime: Date?

    private static let particleCount = 70
    private static let duration: TimeInterval = 1.0

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: !isActive || startTime == nil)) { timeline in
            Canvas { context, size in
                guard let startTime, !particles.isEmpty else { return }

                let elapsed = timeline.date.timeIntervalSince(startTime)
                let progress = min(CGFloat(elapsed / Self.duration), 1)
                let center = CGPoint(x: size.width / 2, y: size.height / 2)

                for particle in particles {
                    let position = position(for: particle, progress: progress, center: center, size: size)
                    let opacity = opacity(for: particle, progress: progress)
                    let currentSize = particle.size * sizeMultiplier(progress: progress)

                    let rect = CGRect(
                        x: position.x - currentSize / 2,
                        y: position.y - currentSize / 2,
                        width: currentSize,
                        height: currentSize
                    )

                    context.fill(
                        Circle().path(in: rect),
                        with: .color(color.opacity(opacity))
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active {
                particles = (0..<Self.particleCount).map { index in
                    UnlockParticle.spawn(index: index)
                }
                startTime = Date()
            } else {
                startTime = nil
                particles = []
            }
        }
    }

    // MARK: - Calculations

    private func position(
        for particle: UnlockParticle,
        progress: CGFloat,
        center: CGPoint,
        size: CGSize
    ) -> CGPoint {
        let adjustedProgress = max(0, (progress - particle.delay) / (1 - particle.delay))
        let easedProgress = 1 - pow(1 - adjustedProgress, 2.5)

        let maxRadius = min(size.width, size.height) * 0.65
        let expandedRadius = particle.initialRadius + easedProgress * maxRadius * particle.speed

        let spiralOffset = easedProgress * 0.25
        let angle = particle.angle + spiralOffset
        let wobble = sin(adjustedProgress * particle.wobbleFrequency * .pi * 2) * 2

        return CGPoint(
            x: center.x + cos(angle) * expandedRadius + wobble,
            y: center.y + sin(angle) * expandedRadius - easedProgress * 8 * particle.speed
        )
    }

    private func opacity(for particle: UnlockParticle, progress: CGFloat) -> CGFloat {
        let adjustedProgress = max(0, (progress - particle.delay) / (1 - particle.delay))

        let fadeInEnd: CGFloat = 0.08
        let fadeOutStart: CGFloat = 0.4

        var result = particle.opacity

        if adjustedProgress < fadeInEnd {
            result *= adjustedProgress / fadeInEnd
        } else if adjustedProgress > fadeOutStart {
            let fadeProgress = (adjustedProgress - fadeOutStart) / (1 - fadeOutStart)
            result *= 1 - pow(fadeProgress, 1.5)
        }

        return result
    }

    private func sizeMultiplier(progress: CGFloat) -> CGFloat {
        let peakPoint: CGFloat = 0.15
        if progress < peakPoint {
            return 0.3 + 0.7 * (progress / peakPoint)
        } else {
            let shrinkProgress = (progress - peakPoint) / (1 - peakPoint)
            return 1.0 - 0.5 * pow(shrinkProgress, 2)
        }
    }
}

// MARK: - Particle Model

private struct UnlockParticle {
    let angle: CGFloat
    let initialRadius: CGFloat
    let speed: CGFloat
    let size: CGFloat
    let opacity: CGFloat
    let delay: CGFloat
    let wobbleFrequency: CGFloat

    static func spawn(index: Int) -> UnlockParticle {
        let seed = Double(index)
        let goldenRatio = 0.618033988749895

        let angle = CGFloat(seed * goldenRatio * 2 * .pi).truncatingRemainder(dividingBy: 2 * .pi)
        let radiusFactor = CGFloat((sin(seed * 1.3) + 1) / 2)
        let speedFactor = CGFloat(0.5 + (cos(seed * 2.1) + 1) / 2 * 0.5)
        let sizeFactor = CGFloat((sin(seed * 3.7) + 1) / 2)
        let opacityFactor = CGFloat(0.6 + (cos(seed * 4.3) + 1) / 2 * 0.4)
        let delayFactor = CGFloat((sin(seed * 5.1) + 1) / 2 * 0.15)
        let wobbleFactor = CGFloat(0.4 + (cos(seed * 6.7) + 1) / 2 * 0.6)

        return UnlockParticle(
            angle: angle,
            initialRadius: radiusFactor * 6,
            speed: speedFactor,
            size: 4 + sizeFactor * 6,
            opacity: opacityFactor,
            delay: delayFactor,
            wobbleFrequency: wobbleFactor
        )
    }
}
