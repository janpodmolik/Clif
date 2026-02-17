import SwiftUI

/// Content displayed on the island - either a pet or a drop zone during creation.
enum IslandContent {
    case pet(any PetDisplayable, windProgress: CGFloat, windDirection: CGFloat, windRhythm: WindRhythm?)
    case dropZone(isHighlighted: Bool, isOnTarget: Bool, isVisible: Bool)

    var displayablePet: (any PetDisplayable)? {
        if case .pet(let pet, _, _, _) = self { return pet }
        return nil
    }
}

/// Displays the island scene with rock, grass, and either a pet or drop zone.
struct IslandView<TransitionContent: View>: View {
    let screenHeight: CGFloat
    let screenWidth: CGFloat?
    let content: IslandContent
    var blowAwayOffsetX: CGFloat = 0
    var blowAwayRotation: CGFloat = 0
    var isBlowingAway: Bool = false
    var archiveOffsetY: CGFloat = 0
    var archiveStretchAmount: CGFloat = 0
    var archiveGlowRadius: CGFloat = 0
    var isAscending: Bool = false
    var showEssenceDropZone: Bool = false
    var isEssenceHighlighted: Bool = false
    var isEssenceOnTarget: Bool = false
    var isEvolutionTransitioning: Bool = false
    var reactionAnimator = PetReactionAnimator()
    @ViewBuilder var transitionContent: TransitionContent
    var onFrameChange: ((CGRect) -> Void)?

    init(
        screenHeight: CGFloat,
        screenWidth: CGFloat? = nil,
        content: IslandContent,
        blowAwayOffsetX: CGFloat = 0,
        blowAwayRotation: CGFloat = 0,
        isBlowingAway: Bool = false,
        archiveOffsetY: CGFloat = 0,
        archiveStretchAmount: CGFloat = 0,
        archiveGlowRadius: CGFloat = 0,
        isAscending: Bool = false,
        showEssenceDropZone: Bool = false,
        isEssenceHighlighted: Bool = false,
        isEssenceOnTarget: Bool = false,
        isEvolutionTransitioning: Bool = false,
        reactionAnimator: PetReactionAnimator = PetReactionAnimator(),
        @ViewBuilder transitionContent: () -> TransitionContent,
        onFrameChange: ((CGRect) -> Void)? = nil
    ) {
        self.screenHeight = screenHeight
        self.screenWidth = screenWidth
        self.content = content
        self.blowAwayOffsetX = blowAwayOffsetX
        self.blowAwayRotation = blowAwayRotation
        self.isBlowingAway = isBlowingAway
        self.archiveOffsetY = archiveOffsetY
        self.archiveStretchAmount = archiveStretchAmount
        self.archiveGlowRadius = archiveGlowRadius
        self.isAscending = isAscending
        self.showEssenceDropZone = showEssenceDropZone
        self.isEssenceHighlighted = isEssenceHighlighted
        self.isEssenceOnTarget = isEssenceOnTarget
        self.isEvolutionTransitioning = isEvolutionTransitioning
        self.reactionAnimator = reactionAnimator
        self.transitionContent = transitionContent()
        self.onFrameChange = onFrameChange
    }

    // Animation state
    @State private var reactionStartTime: TimeInterval = -1
    @State private var currentTapType: PetReactionType = .none
    @State private var currentReactionConfig: ReactionConfig = .none
    @State private var lastAnimationTime: Date = .distantPast
    @State private var autoPlayTimer: Timer?

    // Animation constants
    private let animationCooldown: TimeInterval = 1.0
    private let autoPlayInterval: ClosedRange<Double> = 8...12

    // Landing animation state
    @State private var landingGlowRadius: CGFloat = 0

    // Speech bubble state
    @State private var speechBubbleState = SpeechBubbleState()

    // Pet animation transform for bubble positioning
    @State private var petTransform: PetAnimationTransform = .zero

    // Scared state - pet is near island edge due to sway displacement
    @State private var isScared: Bool = false

    // Pet image size for evolution transition frame
    @State private var petImageSize: CGSize = .zero

    // MARK: - Computed Properties

    private var petHeight: CGFloat { screenHeight * 0.10 }
    private var petOffset: CGFloat { -petHeight }
    private var dropZoneSize: CGFloat { petHeight * 1.5 }
    private var essenceDropZoneSize: CGFloat { petHeight * 2.0 }

    /// The pet to display, used for scale and asset calculations.
    /// For drop zone, uses Blob as reference for consistent sizing.
    private var referencePet: any PetDisplayable {
        content.displayablePet ?? Blob.shared
    }

    private var transitionFrameSize: CGSize {
        if petImageSize == .zero {
            return CGSize(width: petHeight, height: petHeight)
        }
        return petImageSize
    }

    private var windProgress: CGFloat {
        if case .pet(_, let progress, _, _) = content { return progress }
        return 0
    }

    private var windDirection: CGFloat {
        if case .pet(_, _, let direction, _) = content { return direction }
        return 1.0
    }

    private var windRhythm: WindRhythm? {
        if case .pet(_, _, _, let rhythm) = content { return rhythm }
        return nil
    }

    private var windLevel: WindLevel {
        WindLevel.from(progress: windProgress)
    }

    private var windConfig: WindConfig {
        WindConfig.interpolated(progress: windProgress)
    }


    private static var tapTypes: [PetReactionType] {
        [.wiggle, .squeeze, .jiggle, .bounce]
    }

    private func randomTapType() -> PetReactionType {
        Self.tapTypes.randomElement() ?? .wiggle
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            IslandBase(screenHeight: screenHeight)
            islandContent
        }
    }

    // MARK: - Island Content

    @ViewBuilder
    private var islandContent: some View {
        ZStack {
            // Essence drop zone indicator - behind the pet, uses same layout as dropZoneView
            // so it aligns with the pet's visual center regardless of scaleEffect
            if case .pet(let pet, _, _, _) = content, showEssenceDropZone {
                essenceDropZoneView(for: pet)
                    .transition(.opacity)
            }

            switch content {
            case .pet(let pet, _, _, _):
                petView(for: pet)

            case .dropZone(let isHighlighted, let isOnTarget, let isVisible):
                dropZoneView(isHighlighted: isHighlighted, isOnTarget: isOnTarget, isVisible: isVisible)
            }

            // Speech bubble overlay - only for pet content, hidden during blow away and evolution transition
            if case .pet = content, !isBlowingAway, !isAscending, !isEvolutionTransitioning, let config = speechBubbleState.currentConfig {
                SpeechBubbleView(
                    config: config,
                    isVisible: speechBubbleState.isVisible,
                    petTransform: petTransform
                )
            }
        }
        .padding(.top, petHeight * 0.6)
        .offset(y: petOffset)
    }

    // MARK: - Pet View

    private func petAssetName(for pet: any PetDisplayable) -> String {
        if isScared, let scaredName = pet.scaredAssetName(for: windLevel) {
            return scaredName
        }
        return pet.assetName(for: windLevel)
    }

    @ViewBuilder
    private func petView(for pet: any PetDisplayable) -> some View {
        ZStack {
            Image(petAssetName(for: pet))
                .resizable()
                .scaledToFit()
                .frame(height: petHeight)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: PetImageSizeKey.self, value: proxy.size)
                    }
                )
                .onPreferenceChange(PetImageSizeKey.self) { newSize in
                    if newSize != .zero, !isEvolutionTransitioning {
                        petImageSize = newSize
                    }
                }
                .petAnimation(
                    intensity: windConfig.intensity,
                    direction: windDirection,
                    bendCurve: windConfig.bendCurve,
                    swayAmount: windConfig.swayAmount,
                    rotationAmount: windConfig.rotationAmount,
                    tapTime: reactionStartTime,
                    tapType: currentTapType,
                    tapConfig: currentReactionConfig,
                    idleConfig: pet.idleConfig,
                    screenWidth: screenWidth,
                    windRhythm: windRhythm,
                    frozen: isAscending,
                    onTransformUpdate: { transform in
                        petTransform = PetAnimationTransform(
                            rotation: transform.rotation,
                            swayOffset: transform.swayOffset * pet.displayScale,
                            topOffset: transform.topOffset * pet.displayScale
                        )
                        updateScaredState(swayOffset: transform.swayOffset, pet: pet)
                    }
                )
                .scaleEffect(pet.displayScale, anchor: .bottom)
                .offset(x: blowAwayOffsetX)
                .rotationEffect(.degrees(blowAwayRotation), anchor: .bottom)
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .onChange(of: proxy.frame(in: .global)) { _, newFrame in
                                onFrameChange?(newFrame)
                            }
                            .onAppear {
                                onFrameChange?(proxy.frame(in: .global))
                            }
                    }
                }
                .offset(y: archiveOffsetY)
                .modifier(AscensionStretchModifier(stretchAmount: archiveStretchAmount))
                .shadow(color: .white.opacity(archiveGlowRadius > 0 ? 0.8 : 0), radius: archiveGlowRadius)
                .shadow(color: .white.opacity(landingGlowRadius > 0 ? 0.6 : 0), radius: landingGlowRadius)
                .opacity(isEvolutionTransitioning ? 0.0 : 1.0)
                .allowsHitTesting(!isEvolutionTransitioning)
                .onTapGesture {
                    handleTap(for: pet)
                }
                .onAppear {
                    speechBubbleState.startAutoTriggers(windLevel: windLevel)
                    startAutoPlay(for: pet)
                    consumePendingReaction(for: pet)
                }
                .onDisappear {
                    speechBubbleState.stopAutoTriggers()
                    stopAutoPlay()
                }
                .onChange(of: windLevel) { _, newValue in
                    speechBubbleState.updateWindLevel(newValue)
                }
                .onChange(of: isBlowingAway) { _, newValue in
                    if newValue {
                        speechBubbleState.hide()
                    }
                }
                .onChange(of: isAscending) { _, newValue in
                    if newValue {
                        speechBubbleState.hide()
                    }
                }
                .onChange(of: reactionAnimator.trigger) { _, _ in
                    consumePendingReaction(for: pet)
                }

            if isEvolutionTransitioning {
                transitionContent
                    .frame(width: transitionFrameSize.width, height: transitionFrameSize.height)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Essence Drop Zone

    @ViewBuilder
    private func essenceDropZoneView(for pet: any PetDisplayable) -> some View {
        // Use invisible pet image to match exact pet dimensions and scale,
        // same pattern as dropZoneView — ensures correct center alignment
        Image(pet.assetName(for: windLevel))
            .resizable()
            .scaledToFit()
            .frame(height: petHeight)
            .opacity(0)
            .overlay {
                PetDropZone(
                    isHighlighted: isEssenceHighlighted,
                    isOnTarget: isEssenceOnTarget,
                    size: essenceDropZoneSize
                )
            }
            .scaleEffect(pet.displayScale, anchor: .bottom)
    }

    // MARK: - Drop Zone View

    @ViewBuilder
    private func dropZoneView(isHighlighted: Bool, isOnTarget: Bool, isVisible: Bool) -> some View {
        // Use invisible blob image to match exact pet dimensions
        Image(Blob.shared.assetName(for: .none))
            .resizable()
            .scaledToFit()
            .frame(height: petHeight)
            .opacity(0)
            .overlay {
                PetDropZone(isHighlighted: isHighlighted, isOnTarget: isOnTarget, size: dropZoneSize)
                    .opacity(isVisible ? 1 : 0)
            }
            .scaleEffect(Blob.shared.displayScale, anchor: .bottom)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.frame(in: .global)) { _, newFrame in
                            onFrameChange?(newFrame)
                        }
                        .onAppear {
                            onFrameChange?(proxy.frame(in: .global))
                        }
                }
            }
    }

    // MARK: - Scared State

    private func updateScaredState(swayOffset: CGFloat, pet: any PetDisplayable) {
        guard let screenWidth, pet.scaredAssetName(for: windLevel) != nil else {
            if isScared { isScared = false }
            return
        }

        let displacement = abs(swayOffset * pet.displayScale)
        let halfScreen = screenWidth * 0.5
        let ratio = displacement / halfScreen

        // Hysteresis: higher threshold to enter scared, lower to exit
        let shouldBeScared = isScared
            ? ratio > 0.05
            : ratio > 0.25

        if shouldBeScared != isScared {
            isScared = shouldBeScared
        }
    }

    // MARK: - Actions

    private func playAnimation(for pet: any PetDisplayable, withHaptics: Bool) {
        guard Date().timeIntervalSince(lastAnimationTime) >= animationCooldown else { return }
        lastAnimationTime = Date()

        let type = randomTapType()
        let config = pet.reactionConfig(for: type)

        currentTapType = type
        currentReactionConfig = config
        reactionStartTime = Date().timeIntervalSinceReferenceDate

        if withHaptics {
            let generator = UIImpactFeedbackGenerator(style: type.hapticStyle)
            generator.impactOccurred()
        }

        // Attempt to trigger speech bubble (30% chance)
        speechBubbleState.triggerOnTap(windLevel: windLevel)
    }

    private func handleTap(for pet: any PetDisplayable) {
        playAnimation(for: pet, withHaptics: true)
    }

    // MARK: - External Reactions

    private func consumePendingReaction(for pet: any PetDisplayable) {
        guard let reaction = reactionAnimator.consume() else { return }
        let delay: TimeInterval = reaction.glow ? 0.2 : 0

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            currentTapType = reaction.type
            currentReactionConfig = pet.reactionConfig(for: reaction.type)
            reactionStartTime = Date().timeIntervalSinceReferenceDate
            lastAnimationTime = Date()
            HapticType.impactMedium.trigger()

            if reaction.glow {
                withAnimation(.easeOut(duration: 0.3)) { landingGlowRadius = 12 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeIn(duration: 0.4)) { landingGlowRadius = 0 }
                }
            }
        }
    }

    // MARK: - Auto Play

    private func startAutoPlay(for pet: any PetDisplayable) {
        scheduleNextAutoPlay(for: pet)
    }

    private func stopAutoPlay() {
        autoPlayTimer?.invalidate()
        autoPlayTimer = nil
    }

    private func scheduleNextAutoPlay(for pet: any PetDisplayable) {
        let delay = Double.random(in: autoPlayInterval)
        autoPlayTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [self] _ in
            playAnimation(for: pet, withHaptics: false)
            scheduleNextAutoPlay(for: pet)
        }
    }
}

extension IslandView where TransitionContent == EmptyView {
    init(
        screenHeight: CGFloat,
        screenWidth: CGFloat? = nil,
        content: IslandContent,
        blowAwayOffsetX: CGFloat = 0,
        blowAwayRotation: CGFloat = 0,
        isBlowingAway: Bool = false,
        archiveOffsetY: CGFloat = 0,
        archiveStretchAmount: CGFloat = 0,
        archiveGlowRadius: CGFloat = 0,
        isAscending: Bool = false,
        showEssenceDropZone: Bool = false,
        isEssenceHighlighted: Bool = false,
        isEssenceOnTarget: Bool = false,
        reactionAnimator: PetReactionAnimator = PetReactionAnimator(),
        onFrameChange: ((CGRect) -> Void)? = nil
    ) {
        self.init(
            screenHeight: screenHeight,
            screenWidth: screenWidth,
            content: content,
            blowAwayOffsetX: blowAwayOffsetX,
            blowAwayRotation: blowAwayRotation,
            isBlowingAway: isBlowingAway,
            archiveOffsetY: archiveOffsetY,
            archiveStretchAmount: archiveStretchAmount,
            archiveGlowRadius: archiveGlowRadius,
            isAscending: isAscending,
            showEssenceDropZone: showEssenceDropZone,
            isEssenceHighlighted: isEssenceHighlighted,
            isEssenceOnTarget: isEssenceOnTarget,
            reactionAnimator: reactionAnimator,
            transitionContent: { EmptyView() },
            onFrameChange: onFrameChange
        )
    }
}

/// Only applies the ascensionStretch Metal shader when actually stretching.
/// When stretchAmount == 0 (99.9% of the time), renders as a plain pass-through — no GPU cost.
private struct AscensionStretchModifier: ViewModifier {
    let stretchAmount: CGFloat

    func body(content: Content) -> some View {
        if stretchAmount > 0 {
            content.visualEffect { view, proxy in
                view.distortionEffect(
                    ShaderLibrary.ascensionStretch(
                        .float(Float(stretchAmount)),
                        .float2(proxy.size)
                    ),
                    maxSampleOffset: CGSize(width: 0, height: proxy.size.height * 3)
                )
            }
        } else {
            content
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


// MARK: - Preview

#if DEBUG
#Preview("Blob - No Wind") {
    GeometryReader { geometry in
        ZStack {
            Color.blue.opacity(0.3)
            IslandView(
                screenHeight: geometry.size.height,
                screenWidth: geometry.size.width,
                content: .pet(Blob.shared, windProgress: 0, windDirection: 1.0, windRhythm: nil)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}

#Preview("Plant Phase 2 - 50% Progress") {
    GeometryReader { geometry in
        ZStack {
            Color.blue.opacity(0.3)
            IslandView(
                screenHeight: geometry.size.height,
                screenWidth: geometry.size.width,
                content: .pet(EvolutionPath.plant.phase(at: 2)!, windProgress: 0.5, windDirection: 1.0, windRhythm: nil)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}

#Preview("Drop Zone") {
    GeometryReader { geometry in
        ZStack {
            Color.blue.opacity(0.3)
            IslandView(
                screenHeight: geometry.size.height,
                screenWidth: geometry.size.width,
                content: .dropZone(isHighlighted: false, isOnTarget: false, isVisible: true)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}

#Preview("Drop Zone - Highlighted") {
    GeometryReader { geometry in
        ZStack {
            Color.blue.opacity(0.3)
            IslandView(
                screenHeight: geometry.size.height,
                screenWidth: geometry.size.width,
                content: .dropZone(isHighlighted: true, isOnTarget: false, isVisible: true)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}

#Preview("Drop Zone - Snapped") {
    GeometryReader { geometry in
        ZStack {
            Color.blue.opacity(0.3)
            IslandView(
                screenHeight: geometry.size.height,
                screenWidth: geometry.size.width,
                content: .dropZone(isHighlighted: true, isOnTarget: true, isVisible: true)
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}
#endif
