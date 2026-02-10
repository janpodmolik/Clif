import SwiftUI

@Observable
final class AscensionAnimator {
    // MARK: - Animation Transforms

    private(set) var petOffsetY: CGFloat = 0
    private(set) var stretchAmount: CGFloat = 0
    private(set) var cardOffsetY: CGFloat = 0
    private(set) var glowRadius: CGFloat = 0

    // MARK: - State

    private(set) var isAnimating: Bool = false

    /// Whether the pet is currently displaced from its resting position.
    var isAscending: Bool { petOffsetY != 0 }

    /// Set when archive is triggered from PetDetailScreen — animation plays after dismiss.
    var pendingArchive: Bool = false

    // MARK: - API

    /// Triggers the ascension animation — pet rises slowly, card flies off with delay,
    /// then pet stretches and zooms away.
    /// Calls `completion` after the animation finishes (use to perform the actual archive).
    func trigger(screenHeight: CGFloat, completion: @escaping () -> Void) {
        guard !isAnimating else { return }
        let config = AscensionConfig.default
        isAnimating = true

        // Phase 1: Extra slow rise + glow builds
        HapticType.impactSoft.trigger()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: config.slowRiseDuration)) {
                self.petOffsetY = -config.slowRiseDistance
                self.glowRadius = config.glowRadius
            }
        }

        // Phase 1b: Card slides up with delay (starts partway through the rise)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 + config.cardDelay) {
            withAnimation(.easeIn(duration: config.cardDismissDuration)) {
                self.cardOffsetY = -(screenHeight + 200)
            }
        }

        // Phase 2: Fast fly-off with vertical stretch deformation
        let phase2Start = 0.05 + config.slowRiseDuration
        DispatchQueue.main.asyncAfter(deadline: .now() + phase2Start) {
            HapticType.impactMedium.trigger()
            withAnimation(.easeIn(duration: config.fastFlyDuration)) {
                self.petOffsetY = -(screenHeight + 300)
                self.stretchAmount = config.flyStretchAmount
            }
        }

        // Phase 3: Cleanup + completion
        let cleanupTime = phase2Start + config.fastFlyDuration + 0.2
        DispatchQueue.main.asyncAfter(deadline: .now() + cleanupTime) {
            HapticType.notificationSuccess.trigger()
            completion()
            self.reset()
        }
    }

    /// Resets all state without animation.
    func reset() {
        petOffsetY = 0
        stretchAmount = 0
        cardOffsetY = 0
        glowRadius = 0
        isAnimating = false
        pendingArchive = false
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Ascension Animation") {
    struct AscensionPreview: View {
        @State private var animator = AscensionAnimator()
        @State private var archived = false

        var body: some View {
            GeometryReader { geometry in
                ZStack {
                    Color.blue.opacity(0.3)
                        .ignoresSafeArea()

                    // Island + pet
                    IslandView(
                        screenHeight: geometry.size.height,
                        screenWidth: geometry.size.width,
                        content: .pet(
                            EvolutionPath.plant.phase(at: 3)!,
                            windProgress: 0,
                            windDirection: 1.0,
                            windRhythm: nil
                        ),
                        archiveOffsetY: animator.petOffsetY,
                        archiveStretchAmount: animator.stretchAmount,
                        archiveGlowRadius: animator.glowRadius,
                        isAscending: animator.isAscending
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(.container, edges: .bottom)

                    // Mock card
                    if !archived {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .frame(height: 160)
                            .overlay {
                                Text("HomeCard")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(16)
                            .offset(y: animator.cardOffsetY)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }

                    // Controls
                    VStack(spacing: 12) {
                        if archived {
                            Text("Pet archived!")
                                .font(.headline)
                                .foregroundStyle(.green)
                        }

                        HStack(spacing: 16) {
                            Button("Ascend") {
                                archived = false
                                animator.trigger(screenHeight: geometry.size.height) {
                                    archived = true
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(animator.isAnimating)

                            Button("Reset") {
                                animator.reset()
                                archived = false
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    return AscensionPreview()
}
#endif
