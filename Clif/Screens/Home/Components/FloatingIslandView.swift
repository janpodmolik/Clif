import SwiftUI

/// Displays the floating island scene with rock, grass, and animated pet.
struct FloatingIslandView: View {
    let screenHeight: CGFloat
    let screenWidth: CGFloat?
    let pet: any PetDisplayable
    let windLevel: WindLevel
    var windDirection: CGFloat = 1.0

    /// Optional shared wind rhythm for synchronized effects with wind lines.
    var windRhythm: WindRhythm?
    var onPetFrameChange: ((CGRect) -> Void)?

    init(
        screenHeight: CGFloat,
        screenWidth: CGFloat? = nil,
        pet: any PetDisplayable,
        windLevel: WindLevel,
        windDirection: CGFloat = 1.0,
        windRhythm: WindRhythm? = nil,
        onPetFrameChange: ((CGRect) -> Void)? = nil
    ) {
        self.screenHeight = screenHeight
        self.screenWidth = screenWidth
        self.pet = pet
        self.windLevel = windLevel
        self.windDirection = windDirection
        self.windRhythm = windRhythm
        self.onPetFrameChange = onPetFrameChange
    }

    // Internal tap state
    @State private var internalTapTime: TimeInterval = -1
    @State private var currentTapType: TapAnimationType = .none
    @State private var currentTapConfig: TapConfig = .none

    // Speech bubble state
    @State private var speechBubbleState = SpeechBubbleState()

    // Pet animation transform for bubble positioning
    @State private var petTransform: PetAnimationTransform = .zero

    // MARK: - Computed Properties

    private var islandHeight: CGFloat { screenHeight * 0.6 }
    private var petHeight: CGFloat { screenHeight * 0.10 }
    private var petOffset: CGFloat { -petHeight }

    private var windConfig: WindConfig {
        pet.windConfig(for: windLevel)
    }

    private var idleConfig: IdleConfig {
        pet.idleConfig
    }

    private var currentMood: Mood {
        Mood(from: windLevel)
    }

    private static var tapTypes: [TapAnimationType] {
        [.wiggle, .squeeze, .jiggle, .bounce]
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
                Image(pet.assetName(for: windLevel))
                    .resizable()
                    .scaledToFit()
                    .frame(height: petHeight)
                    .background {
                        GeometryReader { proxy in
                            Color.clear
                                .preference(
                                    key: PetFramePreferenceKey.self,
                                    value: proxy.frame(in: .global)
                                )
                        }
                    }
                    .petAnimation(
                        intensity: windConfig.intensity,
                        direction: windDirection,
                        bendCurve: windConfig.bendCurve,
                        swayAmount: windConfig.swayAmount,
                        rotationAmount: windConfig.rotationAmount,
                        tapTime: internalTapTime,
                        tapType: currentTapType,
                        tapConfig: currentTapConfig,
                        idleConfig: idleConfig,
                        screenWidth: screenWidth,
                        windRhythm: windRhythm,
                        onTransformUpdate: { transform in
                            petTransform = PetAnimationTransform(
                                rotation: transform.rotation,
                                swayOffset: transform.swayOffset * pet.displayScale,
                                topOffset: transform.topOffset * pet.displayScale
                            )
                        }
                    )
                    .scaleEffect(pet.displayScale, anchor: .bottom)
                    .onTapGesture {
                        triggerTap()
                    }

                // Speech bubble overlay - follows pet with inertia
                if let config = speechBubbleState.currentConfig {
                    SpeechBubbleView(
                        config: config,
                        isVisible: speechBubbleState.isVisible,
                        petTransform: petTransform
                    )
                }
            }
            .padding(.top, petHeight * 0.6)
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
            .onPreferenceChange(PetFramePreferenceKey.self) { frame in
                onPetFrameChange?(frame)
            }
        }
    }

    // MARK: - Actions

    private func triggerTap() {
        let tapType = randomTapType()
        let tapConfig = pet.tapConfig(for: tapType)

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

private struct PetFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Blob - No Wind") {
    GeometryReader { geometry in
        ZStack {
            Color.blue.opacity(0.3)
            FloatingIslandView(
                screenHeight: geometry.size.height,
                screenWidth: geometry.size.width,
                pet: Blob.shared,
                windLevel: .none
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}

#Preview("Plant Phase 2 - Medium Wind") {
    GeometryReader { geometry in
        ZStack {
            Color.blue.opacity(0.3)
            FloatingIslandView(
                screenHeight: geometry.size.height,
                screenWidth: geometry.size.width,
                pet: EvolutionPath.plant.phase(at: 2)!,
                windLevel: .medium
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}

#Preview("Plant Phase 4 - High Wind") {
    GeometryReader { geometry in
        ZStack {
            Color.blue.opacity(0.3)
            FloatingIslandView(
                screenHeight: geometry.size.height,
                screenWidth: geometry.size.width,
                pet: EvolutionPath.plant.phase(at: 4)!,
                windLevel: .high
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}
#endif
