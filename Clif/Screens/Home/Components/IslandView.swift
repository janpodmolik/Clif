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
struct IslandView: View {
    let screenHeight: CGFloat
    let screenWidth: CGFloat?
    let content: IslandContent
    var blowAwayOffsetX: CGFloat = 0
    var blowAwayRotation: CGFloat = 0
    var isBlowingAway: Bool = false
    var showEssenceDropZone: Bool = false
    var isEssenceHighlighted: Bool = false
    var isEssenceOnTarget: Bool = false
    var onFrameChange: ((CGRect) -> Void)?

    init(
        screenHeight: CGFloat,
        screenWidth: CGFloat? = nil,
        content: IslandContent,
        blowAwayOffsetX: CGFloat = 0,
        blowAwayRotation: CGFloat = 0,
        isBlowingAway: Bool = false,
        showEssenceDropZone: Bool = false,
        isEssenceHighlighted: Bool = false,
        isEssenceOnTarget: Bool = false,
        onFrameChange: ((CGRect) -> Void)? = nil
    ) {
        self.screenHeight = screenHeight
        self.screenWidth = screenWidth
        self.content = content
        self.blowAwayOffsetX = blowAwayOffsetX
        self.blowAwayRotation = blowAwayRotation
        self.isBlowingAway = isBlowingAway
        self.showEssenceDropZone = showEssenceDropZone
        self.isEssenceHighlighted = isEssenceHighlighted
        self.isEssenceOnTarget = isEssenceOnTarget
        self.onFrameChange = onFrameChange
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

    private var petHeight: CGFloat { screenHeight * 0.10 }
    private var petOffset: CGFloat { -petHeight }
    private var dropZoneSize: CGFloat { petHeight * 1.5 }
    private var essenceDropZoneSize: CGFloat { petHeight * 2.0 }

    /// The pet to display, used for scale and asset calculations.
    /// For drop zone, uses Blob as reference for consistent sizing.
    private var referencePet: any PetDisplayable {
        content.displayablePet ?? Blob.shared
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


    private static var tapTypes: [TapAnimationType] {
        [.wiggle, .squeeze, .jiggle, .bounce]
    }

    private func randomTapType() -> TapAnimationType {
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

            // Speech bubble overlay - only for pet content, hidden during blow away
            if case .pet = content, !isBlowingAway, let config = speechBubbleState.currentConfig {
                SpeechBubbleView(
                    config: config,
                    isVisible: speechBubbleState.isVisible,
                    petTransform: petTransform
                )
            }
        }
        .padding(.top, petHeight * 0.6)
        .offset(y: petOffset)
        .onPreferenceChange(IslandFramePreferenceKey.self) { frame in
            onFrameChange?(frame)
        }
    }

    // MARK: - Pet View

    @ViewBuilder
    private func petView(for pet: any PetDisplayable) -> some View {
        Image(pet.assetName(for: windLevel))
            .resizable()
            .scaledToFit()
            .frame(height: petHeight)
            .petAnimation(
                intensity: windConfig.intensity,
                direction: windDirection,
                bendCurve: windConfig.bendCurve,
                swayAmount: windConfig.swayAmount,
                rotationAmount: windConfig.rotationAmount,
                tapTime: internalTapTime,
                tapType: currentTapType,
                tapConfig: currentTapConfig,
                idleConfig: pet.idleConfig,
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
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .preference(
                            key: IslandFramePreferenceKey.self,
                            value: proxy.frame(in: .global)
                        )
                }
            }
            .onTapGesture {
                triggerTap(for: pet)
            }
            .contentTransition(.opacity)
            .animation(.easeInOut(duration: 0.5), value: windProgress)
            .onAppear {
                speechBubbleState.startAutoTriggers(windLevel: windLevel)
            }
            .onDisappear {
                speechBubbleState.stopAutoTriggers()
            }
            .onChange(of: windLevel) { _, newValue in
                speechBubbleState.updateWindLevel(newValue)
            }
            .onChange(of: isBlowingAway) { _, newValue in
                if newValue {
                    speechBubbleState.hide()
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
                        .preference(
                            key: IslandFramePreferenceKey.self,
                            value: proxy.frame(in: .global)
                        )
                }
            }
    }

    // MARK: - Actions

    private func triggerTap(for pet: any PetDisplayable) {
        let tapType = randomTapType()
        let tapConfig = pet.tapConfig(for: tapType)

        currentTapType = tapType
        currentTapConfig = tapConfig
        internalTapTime = Date().timeIntervalSinceReferenceDate

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: tapType.hapticStyle)
        generator.impactOccurred()

        // Attempt to trigger speech bubble (30% chance)
        speechBubbleState.triggerOnTap(windLevel: windLevel)
    }
}

private struct IslandFramePreferenceKey: PreferenceKey {
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
