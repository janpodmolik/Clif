import SwiftUI

/// A standalone view that handles evolution transition between two pet assets.
/// Uses TimelineView for smooth Metal shader-based glow burst animation.
struct EvolutionTransitionView: View {
    let isActive: Bool
    let config: EvolutionTransitionConfig
    let particleConfig: EvolutionParticleConfig
    let oldAssetName: String
    let newAssetName: String
    var oldScale: CGFloat = 1.0
    var newScale: CGFloat = 1.0
    let onComplete: () -> Void

    @State private var startTime: Date?
    @State private var hasCompleted = false

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            TimelineView(.animation) { timeline in
                let progress = calculateProgress(currentTime: timeline.date)

                ZStack {
                    // Old pet (fading out) - hide after flash completes
                    if progress < config.oldImageHidePoint() {
                        petImage(
                            assetName: oldAssetName,
                            size: size,
                            baseScale: oldScale,
                            morphScale: morphScale(progress: progress, isNewImage: false)
                        )
                            .applyGlowBurst(
                                progress: progress,
                                config: config,
                                isNewImage: false,
                                size: size
                            )
                    }

                    // New pet (fading in) - show during flash
                    if progress >= config.assetSwapPoint() {
                        petImage(
                            assetName: newAssetName,
                            size: size,
                            baseScale: newScale,
                            morphScale: morphScale(progress: progress, isNewImage: true)
                        )
                            .applyGlowBurst(
                                progress: progress,
                                config: config,
                                isNewImage: true,
                                size: size
                            )
                    }

                    // Particle overlay
                    if particleConfig.enabled {
                        EvolutionParticleView(
                            progress: progress,
                            config: particleConfig,
                            size: size
                        )
                    }
                }
                .onChange(of: progress >= 1.0) { _, completed in
                    if completed && !hasCompleted {
                        hasCompleted = true
                        onComplete()
                    }
                }
            }
        }
        .onAppear {
            if isActive && startTime == nil {
                startTime = Date()
                hasCompleted = false
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue {
                startTime = Date()
                hasCompleted = false
            }
        }
    }

    private func calculateProgress(currentTime: Date) -> CGFloat {
        guard let start = startTime else { return 0 }
        let elapsed = currentTime.timeIntervalSince(start)
        let progress = elapsed / config.duration
        return min(max(CGFloat(progress), 0), 1)
    }

    private func petImage(
        assetName: String,
        size: CGSize,
        baseScale: CGFloat,
        morphScale: CGSize
    ) -> some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .scaleEffect(
                x: baseScale * morphScale.width,
                y: baseScale * morphScale.height,
                anchor: .bottom
            )
    }

    private func morphScale(progress: CGFloat, isNewImage: Bool) -> CGSize {
        let flashStart = EvolutionTransitionConfig.flashStart
        let assetSwapPoint = config.assetSwapPoint()

        let preSqueezeStart = flashStart * 0.35
        let preSqueezeEnd = flashStart * 0.55
        let squeezeEnd = flashStart * 0.82
        let microHoldDuration = min(CGFloat(0.02), flashStart * 0.08)
        let microHoldEnd = min(flashStart - 0.01, squeezeEnd + microHoldDuration)

        let preSqueezeScale = CGSize(width: 1.05, height: 0.95)
        let squeezeScale = CGSize(width: 1.22, height: 0.82)

        let releaseStartScale = CGSize(width: 0.95, height: 1.05)
        let overshootScale = CGSize(width: 0.90, height: 1.12)
        let expansionEnd = min(assetSwapPoint + 0.12, 0.85)
        let snapEnd = min(expansionEnd + 0.08, 0.92)

        if !isNewImage {
            if progress < preSqueezeStart {
                return CGSize(width: 1, height: 1)
            }
            if progress < preSqueezeEnd {
                let t = smoothStep(normalized(progress, start: preSqueezeStart, end: preSqueezeEnd))
                return lerpSize(from: CGSize(width: 1, height: 1), to: preSqueezeScale, t: t)
            }
            if progress < squeezeEnd {
                let t = smoothStep(normalized(progress, start: preSqueezeEnd, end: squeezeEnd))
                return lerpSize(from: preSqueezeScale, to: squeezeScale, t: t)
            }
            if progress < microHoldEnd {
                return squeezeScale
            }
            return squeezeScale
        }

        if progress < assetSwapPoint {
            return CGSize(width: 1, height: 1)
        }
        if progress < expansionEnd {
            let t = smoothStep(normalized(progress, start: assetSwapPoint, end: expansionEnd))
            return lerpSize(from: releaseStartScale, to: overshootScale, t: t)
        }
        if progress < snapEnd {
            let t = smoothStep(normalized(progress, start: expansionEnd, end: snapEnd))
            return lerpSize(from: overshootScale, to: CGSize(width: 1, height: 1), t: t)
        }

        let t = normalized(progress, start: snapEnd, end: 1.0)
        let wobble = CGFloat(sin(Double(t) * Double.pi * 4)) * (1 - t) * 0.03
        return CGSize(width: 1 - wobble * 0.6, height: 1 + wobble)
    }

    private func normalized(_ value: CGFloat, start: CGFloat, end: CGFloat) -> CGFloat {
        guard end > start else { return 1 }
        return min(max((value - start) / (end - start), 0), 1)
    }

    private func smoothStep(_ t: CGFloat) -> CGFloat {
        t * t * (3 - 2 * t)
    }

    private func lerpSize(from: CGSize, to: CGSize, t: CGFloat) -> CGSize {
        CGSize(
            width: from.width + (to.width - from.width) * t,
            height: from.height + (to.height - from.height) * t
        )
    }
}

// MARK: - Glow Burst Shader

private extension View {
    func applyGlowBurst(
        progress: CGFloat,
        config: EvolutionTransitionConfig,
        isNewImage: Bool,
        size: CGSize
    ) -> some View {
        self.colorEffect(
            ShaderLibrary.evolutionGlowBurst(
                .float(Float(progress)),
                .float3(
                    Float(config.glowColorR),
                    Float(config.glowColorG),
                    Float(config.glowColorB)
                ),
                .float(Float(config.glowPeakIntensity)),
                .float(Float(config.flashDuration / config.duration)),
                .float2(size),
                .float(isNewImage ? 1.0 : 0.0)
            )
        )
    }
}

// MARK: - Preview

#Preview("Evolution Transition") {
    EvolutionTransitionPreview()
}

private struct EvolutionTransitionPreview: View {
    @State private var isActive = false
    @State private var key = UUID()

    var body: some View {
        VStack {
            Spacer()

            if isActive {
                EvolutionTransitionView(
                    isActive: true,
                    config: .default,
                    particleConfig: .default,
                    oldAssetName: "evolutions/plant/happy/1",
                    newAssetName: "evolutions/plant/happy/2",
                    onComplete: {
                        isActive = false
                        key = UUID()
                    }
                )
                .id(key)
                .frame(width: 150, height: 200)
            } else {
                Image("evolutions/plant/happy/1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 200)
            }

            Spacer()

            Button("Trigger Evolution") {
                key = UUID()
                isActive = true
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .background(Color.gray.opacity(0.2))
    }
}
