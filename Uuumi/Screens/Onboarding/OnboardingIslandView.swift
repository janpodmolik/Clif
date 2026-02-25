import SwiftUI

/// Lightweight island view for onboarding — no autoplay, no auto-speech bubbles.
/// Standalone from production `IslandView` to avoid coupling onboarding to home screen logic.
struct OnboardingIslandView: View {
    let screenHeight: CGFloat
    let pet: any PetDisplayable
    var petOpacity: CGFloat = 1.0
    var windProgress: CGFloat = 0
    var eyesOverride: String? = nil
    var speechBubbleConfig: SpeechBubbleConfig? = nil
    var speechBubbleVisible: Bool = false
    var onPetTap: (() -> Void)? = nil
    var showTapHint: Bool = false

    // Pet animation state
    @State private var reactionStartTime: TimeInterval = -1
    @State private var currentTapType: PetReactionType = .none
    @State private var currentReactionConfig: ReactionConfig = .none
    @State private var petTransform: PetAnimationTransform = .zero
    @State private var lastTapTime: Date = .distantPast
    @State private var isTapHintPulsing = false

    private let tapCooldown: TimeInterval = 1.0

    // MARK: - Computed

    private var petHeight: CGFloat { screenHeight * 0.10 }
    private var petOffset: CGFloat { -petHeight }

    private var windConfig: WindConfig {
        WindConfig.interpolated(progress: windProgress)
    }

    private var windLevel: WindLevel {
        WindLevel.from(progress: windProgress)
    }

    private var eyesAssetName: String {
        if let override = eyesOverride {
            return "blob/1/eyes/\(override)"
        }
        return pet.eyesAssetName(for: windLevel)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            IslandBase(screenHeight: screenHeight)
            petContent
        }
    }

    // MARK: - Pet Content

    private var petContent: some View {
        ZStack {
            petImageView
                .overlay(alignment: .top) {
                    if showTapHint {
                        tapHintOverlay
                            .offset(y: -40)
                            .transition(.opacity.animation(.easeOut(duration: 0.4)))
                    }
                }

            SpeechBubbleView(
                config: speechBubbleConfig ?? .default,
                isVisible: speechBubbleVisible,
                petTransform: petTransform
            )
        }
        .padding(.top, petHeight * 0.6)
        .offset(y: petOffset)
    }

    private var tapHintOverlay: some View {
        VStack(spacing: 4) {
            Image(systemName: "hand.tap.fill")
                .font(.title3)
            Text("Tap")
                .font(AppFont.quicksand(.caption, weight: .medium))
        }
        .foregroundStyle(.primary)
        .scaleEffect(isTapHintPulsing ? 1.15 : 1.0)
        .opacity(isTapHintPulsing ? 1.0 : 0.6)
        .animation(
            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
            value: isTapHintPulsing
        )
        .onAppear { isTapHintPulsing = true }
        .allowsHitTesting(false)
    }

    private var petImageView: some View {
        ZStack {
            Image(pet.bodyAssetName(for: windLevel))
                .resizable()
                .scaledToFit()
            Image(eyesAssetName)
                .resizable()
                .scaledToFit()
        }
        .frame(height: petHeight)
        .petAnimation(
            intensity: windConfig.intensity,
            direction: 1.0,
            bendCurve: windConfig.bendCurve,
            swayAmount: windConfig.swayAmount,
            rotationAmount: windConfig.rotationAmount,
            tapTime: reactionStartTime,
            tapType: currentTapType,
            tapConfig: currentReactionConfig,
            idleConfig: pet.idleConfig,
            onTransformUpdate: { transform in
                petTransform = PetAnimationTransform(
                    rotation: transform.rotation,
                    swayOffset: transform.swayOffset * pet.displayScale,
                    topOffset: transform.topOffset * pet.displayScale
                )
            }
        )
        .scaleEffect(pet.displayScale, anchor: .bottom)
        .opacity(petOpacity)
        .onTapGesture {
            handleTap()
        }
    }

    // MARK: - Actions

    private func handleTap() {
        guard Date().timeIntervalSince(lastTapTime) >= tapCooldown else { return }
        lastTapTime = Date()

        let type: PetReactionType = [.wiggle, .squeeze, .jiggle, .bounce].randomElement() ?? .wiggle
        let config = pet.reactionConfig(for: type)

        currentTapType = type
        currentReactionConfig = config
        reactionStartTime = Date().timeIntervalSinceReferenceDate

        let generator = UIImpactFeedbackGenerator(style: type.hapticStyle)
        generator.impactOccurred()

        onPetTap?()
    }
}

#if DEBUG
#Preview {
    GeometryReader { geometry in
        ZStack {
            OnboardingBackgroundView()
            OnboardingIslandView(
                screenHeight: geometry.size.height,
                pet: Blob.shared,
                windProgress: 0.15
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }
}
#endif
