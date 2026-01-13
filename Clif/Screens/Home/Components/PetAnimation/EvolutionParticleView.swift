import SwiftUI

/// Particle effect overlay for evolution transition.
/// Uses Canvas for efficient rendering of many particles.
struct EvolutionParticleView: View {
    let progress: CGFloat
    let config: EvolutionParticleConfig
    let size: CGSize

    @State private var particles: [EvolutionParticle] = []
    @State private var hasSpawned = false

    private var particleColor: Color {
        Color(red: config.colorR, green: config.colorG, blue: config.colorB)
    }

    private var isActive: Bool {
        progress >= config.startProgress && progress <= config.endProgress
    }

    var body: some View {
        Canvas { context, canvasSize in
            guard isActive, !particles.isEmpty else { return }

            let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            let localProgress = normalizedProgress()

            for particle in particles {
                let position = calculatePosition(
                    particle: particle,
                    progress: localProgress,
                    center: center,
                    canvasSize: canvasSize
                )

                let opacity = calculateOpacity(particle: particle, progress: localProgress)
                let currentSize = particle.size * sizeMultiplier(progress: localProgress)

                let rect = CGRect(
                    x: position.x - currentSize / 2,
                    y: position.y - currentSize / 2,
                    width: currentSize,
                    height: currentSize
                )

                context.fill(
                    Circle().path(in: rect),
                    with: .color(particleColor.opacity(opacity))
                )
            }
        }
        .onChange(of: isActive) { _, active in
            if active && !hasSpawned {
                spawnParticles()
            }
            if !active && hasSpawned {
                hasSpawned = false
                particles = []
            }
        }
        .onAppear {
            if isActive && !hasSpawned {
                spawnParticles()
            }
        }
    }

    // MARK: - Particle Spawning

    private func spawnParticles() {
        guard !hasSpawned else { return }
        hasSpawned = true

        particles = (0..<config.particleCount).map { index in
            EvolutionParticle.spawn(config: config, index: index)
        }
    }

    // MARK: - Progress Calculation

    private func normalizedProgress() -> CGFloat {
        let range = config.endProgress - config.startProgress
        guard range > 0 else { return 0 }
        return (progress - config.startProgress) / range
    }

    private func sizeMultiplier(progress: CGFloat) -> CGFloat {
        // Particles grow quickly then slowly shrink as they float away
        let peakPoint: CGFloat = 0.15
        if progress < peakPoint {
            // Quick grow
            return 0.3 + 0.7 * (progress / peakPoint)
        } else {
            // Very slow shrink - particles stay visible longer
            let shrinkProgress = (progress - peakPoint) / (1 - peakPoint)
            return 1.0 - 0.4 * pow(shrinkProgress, 2)
        }
    }

    // MARK: - Opacity Calculation

    private func calculateOpacity(particle: EvolutionParticle, progress: CGFloat) -> CGFloat {
        // Each particle has its own timing based on delay
        let adjustedProgress = max(0, (progress - particle.delay) / (1 - particle.delay))

        // Quick fade in, very slow fade out
        let fadeInEnd: CGFloat = 0.1
        let fadeOutStart: CGFloat = 0.5

        var opacity: CGFloat = particle.opacity

        if adjustedProgress < fadeInEnd {
            // Quick fade in
            opacity *= adjustedProgress / fadeInEnd
        } else if adjustedProgress > fadeOutStart {
            // Slow, gradual fade out - particles linger
            let fadeProgress = (adjustedProgress - fadeOutStart) / (1 - fadeOutStart)
            opacity *= 1 - pow(fadeProgress, 1.5)
        }

        return opacity
    }

    // MARK: - Position Calculation

    private func calculatePosition(
        particle: EvolutionParticle,
        progress: CGFloat,
        center: CGPoint,
        canvasSize: CGSize
    ) -> CGPoint {
        let adjustedProgress = max(0, (progress - particle.delay) / (1 - particle.delay))

        // Slower ease out - particles decelerate gradually as they float away
        let easedProgress = 1 - pow(1 - adjustedProgress, 2.5)

        // Use base (unscaled) size so overscan doesn't inflate the spread
        let maxRadius = min(size.width, size.height) * 0.8

        // Base radius from center
        let baseRadius = particle.initialRadius * 3
        let expandedRadius = baseRadius + easedProgress * maxRadius * particle.speed

        // Slight spiral effect for organic movement
        let spiralOffset = easedProgress * 0.3
        let angle = particle.initialAngle + spiralOffset

        // Subtle wobble for organic feel
        let wobble = sin(adjustedProgress * particle.wobbleFrequency * .pi * 3) * 3

        // Add slight upward drift as particles float away
        let upwardDrift = easedProgress * 15 * particle.speed

        return CGPoint(
            x: center.x + cos(angle) * expandedRadius + wobble,
            y: center.y + sin(angle) * expandedRadius - upwardDrift
        )
    }
}

// MARK: - Particle Model

struct EvolutionParticle: Identifiable {
    let id = UUID()

    let initialAngle: CGFloat
    let initialRadius: CGFloat
    let speed: CGFloat
    let size: CGFloat
    let opacity: CGFloat
    let delay: CGFloat
    let wobbleFrequency: CGFloat

    static func spawn(config: EvolutionParticleConfig, index: Int) -> EvolutionParticle {
        // Use index-based seeding for deterministic but varied particles
        let seed = Double(index)

        // Pseudo-random values based on index (golden ratio for good distribution)
        let angle = CGFloat(seed * 0.618033988749895 * 2 * .pi).truncatingRemainder(dividingBy: 2 * .pi)
        let radiusFactor = CGFloat((sin(seed * 1.3) + 1) / 2)
        let speedFactor = CGFloat(0.5 + (cos(seed * 2.1) + 1) / 2 * 0.5)
        let sizeFactor = CGFloat((sin(seed * 3.7) + 1) / 2)
        let opacityFactor = CGFloat(0.5 + (cos(seed * 4.3) + 1) / 2 * 0.5)
        // Staggered delays so particles don't all appear at once
        let delayFactor = CGFloat((sin(seed * 5.1) + 1) / 2 * 0.2)
        let wobbleFactor = CGFloat(0.4 + (cos(seed * 6.7) + 1) / 2 * 0.6)

        return EvolutionParticle(
            initialAngle: angle,
            initialRadius: radiusFactor * 8,
            speed: speedFactor,
            size: config.minSize + sizeFactor * (config.maxSize - config.minSize),
            opacity: opacityFactor,
            delay: delayFactor,
            wobbleFrequency: wobbleFactor
        )
    }
}

// MARK: - Preview

#Preview("Evolution Particles") {
    EvolutionParticlePreview()
}

private struct EvolutionParticlePreview: View {
    @State private var progress: CGFloat = 0
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Color.black.opacity(0.8)

                EvolutionParticleView(
                    progress: progress,
                    config: EvolutionParticleConfig(
                        particleType: .radialExplosion,
                        enabled: true,
                        particleCount: 80,
                        minSize: 3,
                        maxSize: 8,
                        colorR: 1.0,
                        colorG: 0.95,
                        colorB: 0.8,
                        startProgress: 0.0,
                        peakProgress: 0.5,
                        endProgress: 1.0
                    ),
                    size: CGSize(width: 300, height: 400)
                )
            }
            .frame(width: 300, height: 400)
            .cornerRadius(20)

            HStack {
                Text("Progress: \(progress, specifier: "%.2f")")
                Slider(value: $progress, in: 0...1)
            }
            .padding(.horizontal)

            Button(isAnimating ? "Stop" : "Animate") {
                if isAnimating {
                    isAnimating = false
                } else {
                    progress = 0
                    isAnimating = true
                    animateProgress()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func animateProgress() {
        guard isAnimating else { return }

        withAnimation(.linear(duration: 0.016)) {
            progress += 0.005
        }

        if progress >= 1 {
            progress = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) {
            animateProgress()
        }
    }
}
