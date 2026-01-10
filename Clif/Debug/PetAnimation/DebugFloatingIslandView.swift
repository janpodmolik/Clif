#if DEBUG
import SwiftUI

/// Debug version of FloatingIslandView with full debug parameter support.
/// Use this for testing and configuring animation parameters.
struct DebugFloatingIslandView<Evolution: EvolutionType>: View {
    let screenHeight: CGFloat
    let screenWidth: CGFloat?
    let evolution: Evolution
    let windLevel: WindLevel

    // Debug overrides (nil = use default config)
    var debugWindConfig: WindConfig? = nil
    var windDirection: CGFloat = 1.0
    var windIntensityScale: CGFloat = 1.0

    /// Optional shared wind rhythm for synchronized effects with wind lines.
    var windRhythm: WindRhythm?

    // Debug tap overrides
    var debugTapType: TapAnimationType = .none
    var debugTapConfig: TapConfig? = nil

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
    @State private var currentTapType: TapAnimationType = .none
    @State private var currentTapConfig: TapConfig = .none

    // Pet animation transform for bubble positioning
    @State private var petTransform: PetAnimationTransform = .zero
    @State private var petImageSize: CGSize = .zero

    // MARK: - Computed Properties

    private var islandHeight: CGFloat { screenHeight * 0.6 }
    private var petHeight: CGFloat { screenHeight * 0.10 }
    private var petOffset: CGFloat { -petHeight }

    private var activeWindConfig: WindConfig {
        let baseConfig = debugWindConfig ?? evolution.windConfig(for: windLevel)
        return WindConfig(
            intensity: baseConfig.intensity * windIntensityScale,
            bendCurve: baseConfig.bendCurve,
            swayAmount: baseConfig.swayAmount * windIntensityScale,
            rotationAmount: baseConfig.rotationAmount * windIntensityScale
        )
    }

    private var transitionFrameSize: CGSize {
        if petImageSize == .zero {
            return CGSize(width: petHeight, height: petHeight)
        }
        return petImageSize
    }

    private var activeTapType: TapAnimationType {
        debugTapType != .none ? debugTapType : currentTapType
    }

    private var activeTapConfig: TapConfig {
        // Priority: debug override > internal state > default for current tap type
        if let config = debugTapConfig {
            return config
        }
        if currentTapConfig != .none {
            return currentTapConfig
        }
        // Fallback to default config for the active tap type (fixes external trigger)
        return TapConfig.default(for: activeTapType)
    }

    private var activeIdleConfig: IdleConfig {
        debugIdleConfig ?? AnimationConfigProvider.idleConfig(for: evolution)
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

            // Pet with animation effects, speech bubble, and mood-aware image (top layer)
            ZStack {
                Image(evolution.assetName(for: windLevel))
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
                    .scaleEffect(evolution.displayScale, anchor: .bottom)
                    .petAnimation(
                        intensity: activeWindConfig.intensity,
                        direction: windDirection,
                        bendCurve: activeWindConfig.bendCurve,
                        swayAmount: activeWindConfig.swayAmount,
                        rotationAmount: activeWindConfig.rotationAmount,
                        tapTime: currentTapTime,
                        tapType: activeTapType,
                        tapConfig: activeTapConfig,
                        idleConfig: activeIdleConfig,
                        screenWidth: screenWidth,
                        windRhythm: windRhythm,
                        onTransformUpdate: { transform in
                            petTransform = transform
                        }
                    )
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
        let tapType: TapAnimationType
        if debugTapType != .none {
            tapType = debugTapType
        } else {
            tapType = randomTapType()
        }

        // Get config from provider (or debug override)
        let tapConfig = debugTapConfig ?? AnimationConfigProvider.tapConfig(for: evolution, type: tapType)

        // Update state
        currentTapType = tapType
        currentTapConfig = tapConfig

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
                mood: currentMood,
                source: .random,
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
