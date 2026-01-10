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
                        petImage(assetName: oldAssetName, size: size, scale: oldScale)
                            .applyGlowBurst(
                                progress: progress,
                                config: config,
                                isNewImage: false,
                                size: size
                            )
                    }

                    // New pet (fading in) - show during flash
                    if progress >= config.assetSwapPoint() {
                        petImage(assetName: newAssetName, size: size, scale: newScale)
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

    private func petImage(assetName: String, size: CGSize, scale: CGFloat) -> some View {
        Image(assetName)
            .resizable()
            .scaledToFit()
            .frame(width: size.width, height: size.height)
            .scaleEffect(scale, anchor: .bottom)
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
