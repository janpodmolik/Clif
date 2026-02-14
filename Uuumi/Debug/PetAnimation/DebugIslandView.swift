#if DEBUG
import SwiftUI

/// Debug version of IslandView with full debug parameter support.
/// Use this for testing and configuring animation parameters.
struct DebugIslandView: View {
    let screenHeight: CGFloat
    let screenWidth: CGFloat?
    let pet: any PetDisplayable
    let windLevel: WindLevel

    // Wind config (required - caller decides between custom or interpolated)
    var windConfig: WindConfig
    var windDirection: CGFloat = 1.0
    var windIntensityScale: CGFloat = 1.0
    var idleIntensityScale: CGFloat = 1.0

    /// Optional shared wind rhythm for synchronized effects with wind lines.
    var windRhythm: WindRhythm?

    // Debug peak mode - freeze animation at maximum wind deflection
    var peakMode: Bool = false

    // Debug tap overrides
    var debugTapType: PetReactionType = .none
    var debugReactionConfig: ReactionConfig? = nil

    // Debug idle override
    var debugIdleConfig: IdleConfig? = nil

    // Debug haptic override (for testing different haptic types)
    var debugHapticType: HapticType? = nil
    var debugHapticDuration: TimeInterval = 0.3
    var debugHapticIntensity: Float = 0.8

    // External tap time binding (optional, for debug view)
    var externalTapTime: Binding<TimeInterval>? = nil

    // Speech bubble state (optional external binding for debug)
    var debugSpeechBubbleState: SpeechBubbleState? = nil

    // Custom text for speech bubble (for debug)
    var debugCustomText: String = ""

    // Blow away animation state
    var blowAwayOffsetX: CGFloat = 0
    var blowAwayRotation: CGFloat = 0

    // Evolution transition overlay (replaces pet during transition)
    var evolutionTransitionView: AnyView? = nil

    // Internal tap state (used when no external binding provided)
    @State private var internalTapTime: TimeInterval = -1
    @State private var currentTapType: PetReactionType = .none
    @State private var currentReactionConfig: ReactionConfig = .none

    // Pet animation transform for bubble positioning
    @State private var petTransform: PetAnimationTransform = .zero
    @State private var petImageSize: CGSize = .zero

    // MARK: - Computed Properties

    private var islandHeight: CGFloat { screenHeight * 0.6 }
    private var petHeight: CGFloat { screenHeight * 0.10 }
    private var petOffset: CGFloat { -petHeight }

    private var activeWindConfig: WindConfig {
        WindConfig(
            intensity: windConfig.intensity * windIntensityScale,
            bendCurve: windConfig.bendCurve,
            swayAmount: windConfig.swayAmount * windIntensityScale,
            rotationAmount: windConfig.rotationAmount * windIntensityScale
        )
    }

    private var transitionFrameSize: CGSize {
        if petImageSize == .zero {
            return CGSize(width: petHeight, height: petHeight)
        }
        return petImageSize
    }

    private var activeTapType: PetReactionType {
        debugTapType != .none ? debugTapType : currentTapType
    }

    private var activeReactionConfig: ReactionConfig {
        // Priority: debug override > internal state > default for current tap type
        if let config = debugReactionConfig {
            return config
        }
        if currentReactionConfig != .none {
            return currentReactionConfig
        }
        // Fallback to default config for the active tap type (fixes external trigger)
        return ReactionConfig.default(for: activeTapType)
    }

    private var activeIdleConfig: IdleConfig {
        let baseConfig = debugIdleConfig ?? pet.idleConfig
        guard baseConfig.enabled else { return baseConfig }

        return IdleConfig(
            enabled: true,
            amplitude: baseConfig.amplitude * idleIntensityScale,
            frequency: baseConfig.frequency,
            focusStart: baseConfig.focusStart,
            focusEnd: baseConfig.focusEnd
        )
    }

    private var currentWindLevel: WindLevel {
        windLevel
    }

    private static var tapTypes: [PetReactionType] {
        [.wiggle, .squeeze, .jiggle]
    }

    private func randomTapType() -> PetReactionType {
        Self.tapTypes.randomElement() ?? .wiggle
    }

    private var currentTapTime: TimeInterval {
        externalTapTime?.wrappedValue ?? internalTapTime
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

            // Pet with animation effects, speech bubble, and wind-aware image (top layer)
            ZStack {
                Image(pet.assetName(for: windLevel))
                    .resizable()
                    .scaledToFit()
                    .frame(height: petHeight)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(key: PetImageSizeKey.self, value: proxy.size)
                        }
                    )
                    .onPreferenceChange(PetImageSizeKey.self) { newSize in
                        if newSize != .zero {
                            petImageSize = newSize
                        }
                    }
                    .petAnimation(
                        intensity: activeWindConfig.intensity,
                        direction: windDirection,
                        bendCurve: activeWindConfig.bendCurve,
                        swayAmount: activeWindConfig.swayAmount,
                        rotationAmount: activeWindConfig.rotationAmount,
                        tapTime: currentTapTime,
                        tapType: activeTapType,
                        tapConfig: activeReactionConfig,
                        idleConfig: activeIdleConfig,
                        peakMode: peakMode,
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
                    .offset(x: blowAwayOffsetX)
                    .rotationEffect(.degrees(blowAwayRotation), anchor: .bottom)
                    .opacity(evolutionTransitionView == nil ? 1.0 : 0.0)
                    .allowsHitTesting(evolutionTransitionView == nil)
                    .onTapGesture {
                        triggerTap()
                    }

                if let transitionView = evolutionTransitionView {
                    // Overlay evolution transition while keeping pet animation state alive.
                    transitionView
                        .frame(width: transitionFrameSize.width, height: transitionFrameSize.height)
                        .allowsHitTesting(false)
                }

                // Speech bubble overlay - follows pet with inertia
                if evolutionTransitionView == nil,
                   let bubbleState = debugSpeechBubbleState,
                   let config = bubbleState.currentConfig {
                    SpeechBubbleView(
                        config: config,
                        isVisible: bubbleState.isVisible,
                        petTransform: petTransform
                    )
                }
            }
            .padding(.top, petHeight * 0.6)
            .offset(y: petOffset)
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.5), value: windLevel)
        }
    }

    // MARK: - Actions

    private func triggerTap() {
        // Determine tap type - use debug override or random
        let tapType: PetReactionType
        if debugTapType != .none {
            tapType = debugTapType
        } else {
            tapType = randomTapType()
        }

        // Get config from pet (or debug override)
        let tapConfig = debugReactionConfig ?? pet.reactionConfig(for: tapType)

        // Update state
        currentTapType = tapType
        currentReactionConfig = tapConfig

        let now = Date().timeIntervalSinceReferenceDate

        if let binding = externalTapTime {
            binding.wrappedValue = now
        } else {
            internalTapTime = now
        }

        // Haptic feedback (use debug override if provided, otherwise use tap type's default)
        if let hapticType = debugHapticType {
            hapticType.trigger(duration: debugHapticDuration, intensity: debugHapticIntensity)
        } else {
            let generator = UIImpactFeedbackGenerator(style: tapType.hapticStyle)
            generator.impactOccurred()
        }

        // Trigger speech bubble with custom text if provided
        if let bubbleState = debugSpeechBubbleState {
            bubbleState.forceShow(
                windLevel: currentWindLevel,
                customText: debugCustomText.isEmpty ? nil : debugCustomText
            )
        }
    }
}

private struct PetImageSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next != .zero {
            value = next
        }
    }
}

#Preview {
    PetDebugView()
}
#endif
