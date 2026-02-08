import Combine
import FamilyControls
import SwiftUI

/// Main home screen displaying the floating island scene with pet and status card.
/// Supports horizontal paging when multiple pets exist.
struct HomeScreen: View {
    @Environment(PetManager.self) private var petManager
    @Environment(ArchivedPetManager.self) private var archivedPetManager
    @Environment(EssencePickerCoordinator.self) private var essenceCoordinator
    @Environment(CreatePetCoordinator.self) private var createPetCoordinator
    @Environment(CoinsRewardAnimator.self) private var coinsAnimator

    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .automatic
    @AppStorage("selectedDayTheme") private var dayTheme: DayTheme = .morningHaze
    @AppStorage("selectedNightTheme") private var nightTheme: NightTheme = .deepNight

    @State private var windRhythm = WindRhythm()
    @State private var blowAwayAnimator = BlowAwayAnimator()
    @State private var currentScreenWidth: CGFloat?
    @State private var showPetDetail = false
    @State private var showPresetPicker = false
    @State private var showDeleteSheet = false
    @State private var showSuccessArchivePrompt = false
    @State private var showWindNotCalmAlert = false
    @State private var showAuthorizationAlert = false
    @State private var pendingEssencePicker = false
    @State private var petFrame: CGRect = .zero
    @State private var dropZoneFrame: CGRect = .zero
    @State private var evolutionAnimator = EvolutionTransitionAnimator()

    /// Timer-driven refresh trigger for real-time wind updates during active shield.
    /// Increments every second to force UI recalculation of effectiveWindPoints.
    @State private var refreshTick = 0

    #if DEBUG
    /// Debug state for testing bump visibility (evolve/blown buttons)
    @State private var debugBumpState: DebugBumpState = .actual
    /// Debug override for time-of-day (0.0–1.0). nil = use real time.
    @State private var debugTimeOverride: Double? = nil
    #endif

    private let homeCardInset: CGFloat = 16

    /// Concentric corner radius for the card (based on screen edge distance)
    private var homeCardCornerRadius: CGFloat {
        DeviceMetrics.concentricCornerRadius(inset: homeCardInset)
    }
    /// Hit-test expansion for blob drop during pet creation.
    private let dropTargetExpansion: CGFloat = 40
    /// Hit-test expansion for essence drop on existing pet.
    /// Larger than blob drop because the essence preview is smaller and harder to aim.
    private let essenceDropTargetExpansion: CGFloat = 80
    /// Visual highlight expansion (broader than hit-test to give early feedback).
    private let essenceHighlightExpansion: CGFloat = 100

    /// Whether we're in pet creation mode (empty island shown during entire flow)
    private var isInCreationMode: Bool {
        createPetCoordinator.isShowing || createPetCoordinator.isDropping
    }

    /// Whether the dragged pet is near the drop zone (larger area for visual feedback)
    private var isDropZoneHighlighted: Bool {
        guard createPetCoordinator.dragState.isDragging,
              dropZoneFrame != .zero else { return false }
        let expandedFrame = dropZoneFrame.insetBy(dx: -60, dy: -60)
        return expandedFrame.contains(createPetCoordinator.dragState.dragLocation)
    }

    /// Position of the dragged essence preview (offset from finger).
    private var essencePreviewPosition: CGPoint? {
        guard essenceCoordinator.dragState.isDragging else { return nil }
        return DragPreviewOffset.adjustedPosition(from: essenceCoordinator.dragState.dragLocation)
    }

    /// Whether the dragged essence is near the pet (broad glow feedback).
    private var isEssenceDropZoneHighlighted: Bool {
        guard let position = essencePreviewPosition, petFrame != .zero else { return false }
        return petFrame.insetBy(dx: -essenceHighlightExpansion, dy: -essenceHighlightExpansion)
            .contains(position)
    }

    /// Whether the dragged essence is within the actual drop target (matches petDropFrame used for hit-testing).
    private var isEssenceOnTarget: Bool {
        guard let position = essencePreviewPosition,
              let dropFrame = essenceDropFrame else { return false }
        return dropFrame.contains(position)
    }

    private var currentPet: Pet? { petManager.currentPet }

    private var petDropFrame: CGRect? {
        // Use drop zone frame during creation, pet frame otherwise
        let frame = isInCreationMode ? dropZoneFrame : petFrame
        guard frame != .zero else { return nil }
        return frame.insetBy(dx: -dropTargetExpansion, dy: -dropTargetExpansion)
    }

    private var essenceDropFrame: CGRect? {
        guard petFrame != .zero else { return nil }
        return petFrame.insetBy(dx: -essenceDropTargetExpansion, dy: -essenceDropTargetExpansion)
    }

    private func updatePetDropFrame() {
        createPetCoordinator.petDropFrame = petDropFrame
    }

    var body: some View {
        @Bindable var petManager = petManager
        GeometryReader { geometry in
            ZStack {
                background

                if isInCreationMode || currentPet == nil {
                    // Show empty island during pet creation or when no pet exists
                    emptyIslandPage(geometry: geometry)
                } else if let pet = currentPet {
                    petPage(pet, geometry: geometry)
                }

                #if DEBUG
                // Global debug time slider (visible with or without pet)
                if currentPet == nil {
                    debugTimeSlider
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                        .padding(.horizontal, homeCardInset)
                        .padding(.bottom, 80)
                }
                #endif
            }
            .onAppear {
                currentScreenWidth = geometry.size.width
                // If pet was blown in background, set off-screen immediately
                if currentPet?.isBlownAway == true {
                    blowAwayAnimator.setBlownState(screenWidth: geometry.size.width)
                }
            }
            .onChange(of: geometry.size.width) { _, newWidth in
                currentScreenWidth = newWidth
            }
        }
        .sheet(isPresented: $showPetDetail, onDismiss: {
            if blowAwayAnimator.pendingBlowAway {
                blowAwayAnimator.pendingBlowAway = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    petManager.blowAwayCurrentPet(reason: .userChoice)
                }
            }
            if pendingEssencePicker, let pet = currentPet {
                pendingEssencePicker = false
                handleEvolve(pet)
            }
        }) {
            if let pet = currentPet {
                PetDetailScreen(pet: pet) { action in
                    switch action {
                    case .blowAway:
                        blowAwayAnimator.pendingBlowAway = true
                        showPetDetail = false
                    case .progress:
                        pendingEssencePicker = true
                        showPetDetail = false
                    case .replay:
                        showPetDetail = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            handleReplay()
                        }
                    default:
                        break
                    }
                }
                .presentationDetents([.large])
            }
        }
        .sheet(isPresented: $showPresetPicker) {
            DailyPresetPicker()
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showDeleteSheet) {
            if let pet = currentPet {
                DeletePetSheet(
                    petName: pet.name,
                    showArchiveOption: pet.daysSinceCreation >= PetManager.minimumArchiveDays,
                    onArchive: {
                        petManager.archive(id: pet.id, using: archivedPetManager)
                    },
                    onDelete: {
                        petManager.delete(id: pet.id)
                    }
                )
            }
        }
        .sheet(isPresented: $showSuccessArchivePrompt) {
            if let pet = currentPet {
                SuccessArchiveSheet(
                    petName: pet.name,
                    themeColor: pet.themeColor,
                    onArchive: {
                        petManager.archive(id: pet.id, using: archivedPetManager)
                    }
                )
            }
        }
        .sheet(isPresented: $petManager.needsReauthorization) {
            if let name = petManager.currentPet?.name {
                ReauthorizationSheet(
                    petName: name,
                    onReauthorize: {
                        Task {
                            await reauthorize()
                        }
                    },
                    onDecline: {
                        petManager.handleReauthorizationDeclined()
                    }
                )
            }
        }
        .windNotCalmAlert(isPresented: $showWindNotCalmAlert)
        .alert(
            "Přístup k času u obrazovky",
            isPresented: $showAuthorizationAlert
        ) {
            Button("OK") {}
        } message: {
            Text("Pro vytvoření peta je potřeba povolit přístup k času u obrazovky v Nastavení.")
        }
        .onAppear {
            windRhythm.start()
            // Fallback: check if new day and perform reset if extension missed it
            checkDayResetAndShowPicker()
            // Force immediate refresh to read latest wind from SharedDefaults
            refreshTick += 1
        }
        .onReceive(NotificationCenter.default.publisher(for: .showPresetPicker)) { _ in
            showPresetPicker = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Force refresh when returning from background to read latest wind
            refreshTick += 1
        }
        .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
            // Tick every second to update wind display from SharedDefaults
            // This forces SwiftUI to re-read pet.windProgress which reads from UserDefaults
            refreshTick += 1
        }
        .onDisappear {
            windRhythm.stop()
        }
        .onChange(of: petFrame) { _, _ in
            updatePetDropFrame()
            if essenceCoordinator.isShowing {
                essenceCoordinator.petDropFrame = essenceDropFrame
            }
        }
        .onChange(of: dropZoneFrame) { _, _ in
            updatePetDropFrame()
        }
        .onChange(of: isInCreationMode) { _, _ in
            updatePetDropFrame()
        }
        .onChange(of: currentPet?.id) { _, _ in
            // Reset animators when pet changes (e.g. deleted + new pet created)
            blowAwayAnimator.reset()
            evolutionAnimator.reset()
        }
        .onChange(of: currentPet?.isBlownAway) { oldValue, newValue in
            if newValue == true && oldValue != true, let screenWidth = currentScreenWidth {
                blowAwayAnimator.trigger(screenWidth: screenWidth)
            }
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var background: some View {
        #if DEBUG
        if let time = debugTimeOverride {
            AutomaticBackgroundView(timeOverride: time)
        } else {
            defaultBackground
        }
        #else
        defaultBackground
        #endif
    }

    @ViewBuilder
    private var defaultBackground: some View {
        switch appearanceMode {
        case .automatic:
            AutomaticBackgroundView()
        case .light:
            DayBackgroundView(theme: dayTheme)
        case .dark:
            NightBackgroundView(theme: nightTheme)
        }
    }

    // MARK: - Empty Island (Pet Creation)

    private func emptyIslandPage(geometry: GeometryProxy) -> some View {
        ZStack {
            // Island with drop zone
            IslandView(
                screenHeight: geometry.size.height,
                screenWidth: geometry.size.width,
                content: createPetCoordinator.isDropping
                    ? .dropZone(
                        isHighlighted: isDropZoneHighlighted,
                        isOnTarget: createPetCoordinator.dragState.isOnTarget,
                        isVisible: true
                    )
                    : .dropZone(isHighlighted: false, isOnTarget: false, isVisible: false),
                onFrameChange: { frame in
                    dropZoneFrame = frame
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(.container, edges: .bottom)

            // Show empty island card only when not in creation mode
            if !isInCreationMode {
                emptyIslandCard
                    .modifier(HomeCardBackgroundModifier(cornerRadius: homeCardCornerRadius))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(homeCardInset)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
    }

    // MARK: - Empty Island Card

    private var emptyIslandCard: some View {
        EmptyIslandCard {
            Task {
                await requestAuthorizationAndCreatePet()
            }
        }
    }

    private func reauthorize() async {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            petManager.handleReauthorizationSuccess()
        } catch {
            // Authorization failed — keep sheet open so next .active cycle re-triggers
            petManager.needsReauthorization = false
        }
    }

    private func requestAuthorizationAndCreatePet() async {
        let status = AuthorizationCenter.shared.authorizationStatus
        if status == .approved {
            createPetCoordinator.show { _ in }
            return
        }

        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            createPetCoordinator.show { _ in }
        } catch {
            showAuthorizationAlert = true
        }
    }

    // MARK: - Single Pet Page

    private func petPage(_ pet: Pet, geometry: GeometryProxy) -> some View {
        // Force recalculation when refreshTick changes (used to trigger SwiftUI update)
        let _ = refreshTick
        // Capture effective wind progress (recalculated each tick when shield active)
        let effectiveProgress = pet.windProgress

        return ZStack {
            WindLinesView(
                windProgress: blowAwayAnimator.windBurstActive ? 1.0 : effectiveProgress,
                direction: 1.0,
                windAreaTop: 0.25,
                windAreaBottom: 0.50,
                overrideConfig: blowAwayAnimator.windBurstActive ? .burst : nil,
                windRhythm: blowAwayAnimator.windBurstActive ? nil : windRhythm
            )

            IslandView(
                screenHeight: geometry.size.height,
                screenWidth: geometry.size.width,
                content: .pet(
                    pet.phase ?? Blob.shared,
                    windProgress: effectiveProgress,
                    windDirection: 1.0,
                    windRhythm: windRhythm
                ),
                blowAwayOffsetX: blowAwayAnimator.offsetX,
                blowAwayRotation: blowAwayAnimator.rotation,
                isBlowingAway: blowAwayAnimator.isBlowingAway,
                showEssenceDropZone: essenceCoordinator.hasSelectedEssence,
                isEssenceHighlighted: isEssenceDropZoneHighlighted,
                isEssenceOnTarget: isEssenceOnTarget,
                isEvolutionTransitioning: evolutionAnimator.isShowingTransition,
                transitionContent: {
                    if evolutionAnimator.isShowingTransition {
                        EvolutionTransitionView(
                            isActive: true,
                            config: evolutionAnimator.transitionConfig,
                            particleConfig: evolutionAnimator.particleConfig,
                            oldAssetName: evolutionAnimator.oldAssetName,
                            newAssetName: evolutionAnimator.newAssetName,
                            oldScale: evolutionAnimator.oldScale,
                            newScale: evolutionAnimator.newScale,
                            cameraTransform: .init(
                                get: { evolutionAnimator.cameraTransform },
                                set: { evolutionAnimator.cameraTransform = $0 }
                            ),
                            onComplete: {
                                evolutionAnimator.complete()
                                coinsAnimator.showReward(CoinRewards.evolution)
                                if pet.isFullyEvolved {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        showSuccessArchivePrompt = true
                                    }
                                }
                            }
                        )
                        .id(evolutionAnimator.transitionKey)
                    }
                },
                onFrameChange: { frame in
                    petFrame = frame
                }
            )
            .scaleEffect(evolutionAnimator.cameraTransform.scale, anchor: .top)
            .offset(evolutionAnimator.cameraTransform.offset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(.container, edges: .bottom)

            homeCard(for: pet, windProgress: effectiveProgress)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(homeCardInset)

            ReplayOverlayView(isVisible: blowAwayAnimator.replayOverlayVisible, petFrame: petFrame)

            #if DEBUG
            VStack(spacing: 8) {
                debugTimeSlider

                HStack(spacing: 8) {
                    debugBumpToggle
                    debugCoinsButton
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(.horizontal, homeCardInset)
            .padding(.bottom, 80)
            #endif
        }
    }


    // MARK: - Home Card

    private func homeCard(for pet: Pet, windProgress: CGFloat) -> some View {
        #if DEBUG
        HomeCardView(
            pet: pet,
            streakCount: pet.totalDays,
            showDetailButton: true,
            windProgress: windProgress,
            debugBumpState: debugBumpState,
            onAction: { handleAction($0, for: pet) }
        )
        #else
        HomeCardView(
            pet: pet,
            streakCount: pet.totalDays,
            showDetailButton: true,
            windProgress: windProgress,
            onAction: { handleAction($0, for: pet) }
        )
        #endif
    }

    private func handleAction(_ action: HomeCardAction, for pet: Pet) {
        switch action {
        case .detail:
            showPetDetail = true
        case .evolve:
            guard pet.windLevel == .none else {
                showWindNotCalmAlert = true
                return
            }
            handleEvolve(pet)
        case .replay:
            handleReplay()
        case .delete:
            showDeleteSheet = true
        case .archive:
            guard pet.windLevel == .none else {
                showWindNotCalmAlert = true
                return
            }
            showSuccessArchivePrompt = true
        }
    }

    // MARK: - Blow Away

    private func handleReplay() {
        guard let screenWidth = currentScreenWidth,
              !blowAwayAnimator.isAnimating else { return }
        blowAwayAnimator.replay(screenWidth: screenWidth)
    }

    // MARK: - Actions

    private func handleEvolve(_ pet: Pet) {
        if pet.isBlob {
            essenceCoordinator.show(petDropFrame: essenceDropFrame) { essence in
                evolutionAnimator.triggerEssenceApplication(pet: pet, essence: essence)
            }
        } else {
            evolutionAnimator.trigger(pet: pet)
        }
    }

    // MARK: - Daily Reset & Preset Picker

    private func checkDayResetAndShowPicker() {
        // Fallback: if extension didn't catch the new day, perform reset here
        if SharedDefaults.isNewDay {
            SharedDefaults.performDailyResetIfNeeded()
            ShieldManager.shared.activateStoreFromStoredTokens()
        }

        // Show preset picker if:
        // 1. There is an active pet
        // 2. Day start shield is active (set at day reset)
        // 3. Preset not yet selected today
        guard currentPet != nil,
              SharedDefaults.isDayStartShieldActive,
              !SharedDefaults.windPresetLockedForToday else {
            return
        }

        // Small delay to let view fully appear
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showPresetPicker = true
        }
    }
}

// MARK: - HomeCardBackgroundModifier

/// Applies background with sheet-style corner radius for visual consistency
private struct HomeCardBackgroundModifier: ViewModifier {
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        // Use consistent corner radius across all iOS versions
        // ConcentricRectangle doesn't work well here because the card is inside safe area
        content.background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: cornerRadius)
        )
    }
}

// MARK: - Debug Bump Toggle

#if DEBUG
private extension HomeScreen {
    var debugBumpToggle: some View {
        Menu {
            ForEach(DebugBumpState.allCases, id: \.self) { state in
                Button {
                    debugBumpState = state
                } label: {
                    HStack {
                        Text(state.rawValue)
                        if debugBumpState == state {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "ladybug.fill")
                Text(debugBumpState.rawValue)
            }
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }

    var debugCoinsButton: some View {
        Button {
            coinsAnimator.showReward(5)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "u.circle.fill")
                Text("+5")
            }
            .font(.system(size: 12, weight: .medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }

    var debugTimeSlider: some View {
        VStack(spacing: 4) {
            HStack {
                Text(debugTimeOverride != nil ? debugTimeLabel : "Time: auto")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                Spacer()
                Button(debugTimeOverride != nil ? "Reset" : "Override") {
                    if debugTimeOverride != nil {
                        debugTimeOverride = nil
                    } else {
                        debugTimeOverride = SkyGradient.timeOfDay()
                    }
                }
                .font(.system(size: 11, weight: .medium))
            }

            if debugTimeOverride != nil {
                Slider(
                    value: Binding(
                        get: { debugTimeOverride ?? 0 },
                        set: { debugTimeOverride = $0 }
                    ),
                    in: 0...1
                )
                .tint(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var debugTimeLabel: String {
        guard let time = debugTimeOverride else { return "" }
        let totalSeconds = time * 24 * 60 * 60
        let hours = Int(totalSeconds) / 3600
        let minutes = (Int(totalSeconds) % 3600) / 60
        return String(format: "Time: %02d:%02d", hours, minutes)
    }
}
#endif

#Preview {
    HomeScreen()
        .environment(PetManager.mock())
        .environment(ArchivedPetManager.mock())
        .environment(EssencePickerCoordinator())
        .environment(CreatePetCoordinator())
        .environment(CoinsRewardAnimator())
}
