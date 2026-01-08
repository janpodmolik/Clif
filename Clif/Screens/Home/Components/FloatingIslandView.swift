import SwiftUI

/// Displays the floating island scene with rock, grass, and animated pet.
struct FloatingIslandView<Evolution: EvolutionType>: View {
    let screenHeight: CGFloat
    let evolution: Evolution
    let windLevel: WindLevel

    // Internal tap state
    @State private var internalTapTime: TimeInterval = -1
    @State private var currentTapType: TapAnimationType = .none
    @State private var currentTapConfig: TapConfig = .none

    // Speech bubble state
    @State private var speechBubbleState = SpeechBubbleState()

    // MARK: - Computed Properties

    private var islandHeight: CGFloat { screenHeight * 0.6 }
    private var petHeight: CGFloat { screenHeight * 0.15 }
    private var petOffset: CGFloat { -petHeight * 0.65 }

    private var windConfig: WindConfig {
        evolution.windConfig(for: windLevel)
    }

    private var idleConfig: IdleConfig {
        AnimationConfigProvider.idleConfig(for: evolution)
    }

    private var currentMood: Mood {
        Mood(from: windLevel)
    }

    private static var tapTypes: [TapAnimationType] {
        [.wiggle, .squeeze, .jiggle]
    }

    private func randomTapType() -> TapAnimationType {
        Self.tapTypes.randomElement() ?? .wiggle
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Rock with grass overlay (base layer)
            Image("rock")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: islandHeight)
                .overlay(alignment: .top) {
                    Image("grass")
                        .resizable()
                        .scaledToFit()
                }

            // Pet with animation effects, speech bubble, and mood-aware image (top layer)
            ZStack {
                Image(evolution.assetName(for: windLevel))
                    .resizable()
                    .scaledToFit()
                    .frame(height: petHeight)
                    .petAnimation(
                        intensity: windConfig.intensity,
                        direction: 1.0,
                        bendCurve: windConfig.bendCurve,
                        swayAmount: windConfig.swayAmount,
                        rotationAmount: windConfig.rotationAmount,
                        tapTime: internalTapTime,
                        tapType: currentTapType,
                        tapConfig: currentTapConfig,
                        idleConfig: idleConfig
                    )
                    .onTapGesture {
                        triggerTap()
                    }

                // Speech bubble overlay
                if let config = speechBubbleState.currentConfig {
                    SpeechBubbleView(config: config, isVisible: speechBubbleState.isVisible)
                }
            }
            .offset(y: petOffset)
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.5), value: windLevel)
            .onAppear {
                speechBubbleState.startAutoTriggers(mood: currentMood)
            }
            .onDisappear {
                speechBubbleState.stopAutoTriggers()
            }
            .onChange(of: windLevel) { _, newValue in
                speechBubbleState.updateMood(Mood(from: newValue))
            }
        }
    }

    // MARK: - Actions

    private func triggerTap() {
        let tapType = randomTapType()
        let tapConfig = AnimationConfigProvider.tapConfig(for: evolution, type: tapType)

        currentTapType = tapType
        currentTapConfig = tapConfig
        internalTapTime = Date().timeIntervalSinceReferenceDate

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: tapType.hapticStyle)
        generator.impactOccurred()

        // Attempt to trigger speech bubble (30% chance)
        speechBubbleState.triggerOnTap(mood: currentMood)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    PetDebugView()
}
#endif
