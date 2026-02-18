import SwiftUI

/// A standalone view that handles evolution transition between two pet assets.
/// Uses TimelineView for smooth Metal shader-based glow burst animation.
struct EvolutionTransitionView: View {
    let isActive: Bool
    let config: EvolutionTransitionConfig
    let particleConfig: EvolutionParticleConfig
    let oldAssetName: String
    let newAssetName: String
    let oldEyesAssetName: String
    let newEyesAssetName: String
    var oldScale: CGFloat = 1.0
    var newScale: CGFloat = 1.0
    var sustainedHaptic: HapticType? = .continuousBuzz
    var flashHaptic: HapticType? = .impactHeavy
    var hapticIntensity: Float = 1.0
    var cameraTransform: Binding<EvolutionCameraTransform>? = nil
    let onComplete: () -> Void

    @State private var startTime: Date?
    @State private var hasCompleted = false
    @State private var hasTriggeredSustainedHaptic = false
    @State private var hasTriggeredFlash = false

    private enum MorphTiming {
        static let preSqueezeStart: CGFloat = 0.35
        static let preSqueezeEnd: CGFloat = 0.55
        static let squeezeEnd: CGFloat = 0.82
    }

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size

            TimelineView(.animation) { timeline in
                let progress = calculateProgress(currentTime: timeline.date)
                let glowOpacity = glowIntensity(progress: progress)
                let cameraScale = cameraScale(progress: progress)
                let shockwave = shockwaveState(progress: progress)
                let shakeOffset = cameraShakeOffset(progress: progress)
                let currentTransform = EvolutionCameraTransform(scale: cameraScale, offset: shakeOffset)
                let particleOverscan = particleOverscanScale(for: size)

                ZStack {
                    if glowOpacity > 0 {
                        backgroundGlow(size: size)
                            .opacity(glowOpacity)
                            .blendMode(.screen)
                    }

                    if shockwave.opacity > 0 {
                        shockwaveRing(size: size)
                            .scaleEffect(shockwave.scale)
                            .opacity(shockwave.opacity)
                            .blendMode(.screen)
                    }

                    // Old pet (fading out) - hide after flash completes
                    if progress < config.oldImageHidePoint() {
                        petImage(
                            assetName: oldAssetName,
                            eyesAssetName: oldEyesAssetName,
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
                            eyesAssetName: newEyesAssetName,
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
                        .frame(width: size.width * particleOverscan, height: size.height * particleOverscan)
                        .position(x: size.width / 2, y: size.height / 2)
                        .blendMode(.screen)
                    }
                }
                .scaleEffect(cameraScale)
                .offset(shakeOffset)
                .preference(key: CameraTransformPreferenceKey.self, value: currentTransform)
                .onChange(of: progress >= squashStartPoint()) { _, reached in
                    if reached && !hasTriggeredSustainedHaptic {
                        let duration = max(0, (flashTriggerPoint() - squashStartPoint()) * config.duration)
                        triggerSustainedHapticIfNeeded(duration: duration)
                    }
                }
                .onChange(of: progress >= flashTriggerPoint()) { _, reached in
                    if reached && !hasTriggeredFlash {
                        hasTriggeredFlash = true
                        triggerFlashImpact()
                    }
                }
                .onChange(of: progress >= 1.0) { _, completed in
                    if completed && !hasCompleted {
                        hasCompleted = true
                        resetCameraTransform()
                        onComplete()
                    }
                }
            }
        }
        .onPreferenceChange(CameraTransformPreferenceKey.self) { newValue in
            guard let binding = cameraTransform else { return }
            binding.wrappedValue = newValue
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
                hasTriggeredFlash = false
                hasTriggeredSustainedHaptic = false
                resetCameraTransform()
            } else {
                hasTriggeredSustainedHaptic = false
                resetCameraTransform()
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
        eyesAssetName: String,
        size: CGSize,
        baseScale: CGFloat,
        morphScale: CGSize
    ) -> some View {
        ZStack {
            Image(assetName)
                .resizable()
                .scaledToFit()
            Image(eyesAssetName)
                .resizable()
                .scaledToFit()
        }
            .frame(width: size.width, height: size.height)
            .scaleEffect(
                x: baseScale * morphScale.width,
                y: baseScale * morphScale.height,
                anchor: .bottom
            )
    }

    private var glowColor: Color {
        Color(red: particleConfig.colorR, green: particleConfig.colorG, blue: particleConfig.colorB)
    }

    private func backgroundGlow(size: CGSize) -> some View {
        let screenSize = UIScreen.main.bounds.size
        let glowSize = CGSize(
            width: max(size.width, screenSize.width),
            height: max(size.height, screenSize.height)
        )
        return RadialGradient(
            gradient: Gradient(colors: [
                glowColor.opacity(0.9),
                glowColor.opacity(0.3),
                .clear
            ]),
            center: .center,
            startRadius: 0,
            endRadius: max(glowSize.width, glowSize.height) * 0.9
        )
        .frame(width: glowSize.width, height: glowSize.height)
        .position(x: size.width / 2, y: size.height / 2)
        .scaleEffect(1.4)
    }

    private func shockwaveRing(size: CGSize) -> some View {
        Circle()
            .stroke(glowColor.opacity(0.85), lineWidth: max(2, min(size.width, size.height) * 0.02))
            .frame(width: size.width * 0.8, height: size.width * 0.8)
    }

    private func particleOverscanScale(for size: CGSize) -> CGFloat {
        let minDimension = max(1, min(size.width, size.height))
        let maxRadius = minDimension * 0.8
        // Keep room for max base radius, upward drift, and wobble.
        let maxExtraOffset: CGFloat = 24 + 15 + 3
        return max(1.0, (maxRadius + maxExtraOffset) * 2 / minDimension)
    }

    private func glowIntensity(progress: CGFloat) -> CGFloat {
        let peak = flashTriggerPoint()
        let start = max(peak - 0.02, 0)
        let end = min(peak + 0.18, 1.0)

        if progress < start {
            return 0
        }
        if progress < peak {
            let t = smoothStep(normalized(progress, start: start, end: peak))
            return 0.25 + t * 0.75
        }
        if progress < end {
            let t = smoothStep(normalized(progress, start: peak, end: end))
            return 1 - t
        }
        return 0
    }

    private func cameraScale(progress: CGFloat) -> CGFloat {
        let preStart = cameraPreZoomStartPoint()
        let flash = EvolutionTransitionConfig.flashStart
        let end = min(flash + 0.10, 1.0)
        let preScale: CGFloat = 1.08
        let maxScale: CGFloat = 1.20

        if progress < preStart {
            return 1
        }
        if progress < flash {
            let t = smoothStep(normalized(progress, start: preStart, end: flash))
            return 1 + (preScale - 1) * t
        }
        if progress < end {
            let t = normalized(progress, start: flash, end: end)
            return maxScale - (maxScale - 1) * t
        }
        return 1
    }

    private func shockwaveState(progress: CGFloat) -> (scale: CGFloat, opacity: CGFloat) {
        let start = max(EvolutionTransitionConfig.flashStart - 0.005, 0)
        let end = min(EvolutionTransitionConfig.flashStart + 0.18, 1.0)

        if progress < start || progress > end {
            return (scale: 1, opacity: 0)
        }

        let t = smoothStep(normalized(progress, start: start, end: end))
        let scale = 0.3 + t * 1.4
        let opacity = (1 - t) * 0.8
        return (scale: scale, opacity: opacity)
    }

    private func cameraShakeOffset(progress: CGFloat) -> CGSize {
        let start = max(EvolutionTransitionConfig.flashStart - 0.01, 0)
        let end = min(EvolutionTransitionConfig.flashStart + 0.12, 1.0)

        guard progress >= start && progress <= end else { return .zero }

        let t = normalized(progress, start: start, end: end)
        let decay = 1 - t
        let amplitude: CGFloat = 6 * decay
        let phase = Double(progress) * 120

        return CGSize(
            width: CGFloat(sin(phase)) * amplitude,
            height: CGFloat(cos(phase * 1.3)) * amplitude * 0.6
        )
    }

    private func flashTriggerPoint() -> CGFloat {
        config.assetSwapPoint()
    }

    private func squashStartPoint() -> CGFloat {
        EvolutionTransitionConfig.flashStart * MorphTiming.preSqueezeEnd
    }

    private func cameraPreZoomStartPoint() -> CGFloat {
        0.02
    }

    private func morphScale(progress: CGFloat, isNewImage: Bool) -> CGSize {
        let flashStart = EvolutionTransitionConfig.flashStart
        let assetSwapPoint = config.assetSwapPoint()

        let preSqueezeStart = flashStart * MorphTiming.preSqueezeStart
        let preSqueezeEnd = flashStart * MorphTiming.preSqueezeEnd
        let squeezeEnd = flashStart * MorphTiming.squeezeEnd
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

    private func triggerSustainedHapticIfNeeded(duration: TimeInterval) {
        guard !hasTriggeredSustainedHaptic else { return }
        hasTriggeredSustainedHaptic = true
        sustainedHaptic?.trigger(duration: duration, intensity: hapticIntensity)
    }

    private func triggerFlashImpact() {
        flashHaptic?.trigger()
        SoundManager.shared.play(.evolveBurst)
    }

    private func resetCameraTransform() {
        guard let binding = cameraTransform else { return }
        DispatchQueue.main.async {
            binding.wrappedValue = .identity
        }
    }
}

struct EvolutionCameraTransform: Equatable {
    var scale: CGFloat
    var offset: CGSize

    static let identity = EvolutionCameraTransform(scale: 1.0, offset: .zero)
}

private struct CameraTransformPreferenceKey: PreferenceKey {
    static var defaultValue: EvolutionCameraTransform = .identity

    static func reduce(value: inout EvolutionCameraTransform, nextValue: () -> EvolutionCameraTransform) {
        value = nextValue()
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
                    oldAssetName: "evolutions/plant/1/body",
                    newAssetName: "evolutions/plant/2/body",
                    oldEyesAssetName: "evolutions/plant/1/eyes/happy",
                    newEyesAssetName: "evolutions/plant/2/eyes/happy",
                    onComplete: {
                        isActive = false
                        key = UUID()
                    }
                )
                .id(key)
                .frame(width: 150, height: 200)
            } else {
                PetImage(
                    bodyAssetName: "evolutions/plant/1/body",
                    eyesAssetName: "evolutions/plant/1/eyes/happy"
                )
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
