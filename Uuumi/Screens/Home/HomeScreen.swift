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
    @Environment(EssenceCatalogManager.self) private var essenceCatalogManager
    @Environment(SyncManager.self) private var syncManager
    @Environment(CoinsRewardAnimator.self) private var coinsAnimator
    @Environment(AnalyticsManager.self) private var analytics
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.fullScreenHeight) private var fullScreenHeight

    @State private var windRhythm = WindRhythm()
    @State private var blowAwayAnimator = BlowAwayAnimator()
    @State private var ascensionAnimator = AscensionAnimator()
    @State private var currentScreenWidth: CGFloat?
    @State private var currentScreenHeight: CGFloat?
    @State private var showPetDetail = false
    @State private var showDeleteSheet = false
    @State private var showSuccessArchivePrompt = false
    @State private var showWindNotCalmAlert = false
    @State private var showAuthorizationAlert = false
    @State private var showEvolutionUpsell = false
    @State private var showEssenceUpsell = false
    @State private var showPremiumSheet = false
    @State private var pendingEvolveAction: (() -> Void)?
    @State private var pendingEssenceAction: (() -> Void)?
    @State private var petFrame: CGRect = .zero
    @State private var dropZoneFrame: CGRect = .zero
    @State private var evolutionAnimator = EvolutionTransitionAnimator()
    @State private var reactionAnimator = PetReactionAnimator()
    @State private var cardRevealed = false

    /// Timer-driven refresh trigger for real-time wind updates during active shield.
    /// Increments periodically to force UI recalculation of effectiveWindPoints.
    @State private var refreshTick = 0
    @State private var refreshTimer: Timer?

    #if DEBUG
    /// Debug state for testing bump visibility (evolve/blown buttons)
    @State private var debugBumpState: DebugBumpState = .actual
    /// Debug override for time-of-day (0.0–1.0). nil = use real time.
    @State private var debugTimeOverride: Double? = nil
    private var screenshotMode: Bool { ScreenshotMode.shared.isActive }
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
                #if DEBUG
                HomeBackgroundView(debugTimeOverride: debugTimeOverride)
                #else
                HomeBackgroundView()
                #endif

                // Pet-specific layers (wind lines, replay overlay) — only when pet exists
                if let pet = currentPet, !isInCreationMode {
                    petOverlays(pet, geometry: geometry)
                }

                // Single persistent island — content switches between pet and drop zone
                islandView(geometry: geometry)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(.container, edges: .bottom)

                // Card layer — switches between homeCard and emptyIslandCard
                ZStack {
                    if let pet = currentPet, !isInCreationMode, cardRevealed {
                        homeCard(for: pet, windProgress: pet.windProgress)
                            .offset(y: ascensionAnimator.cardOffsetY)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(homeCardInset)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    } else if !isInCreationMode, cardRevealed {
                        emptyIslandCard
                            .modifier(HomeCardBackgroundModifier(cornerRadius: homeCardCornerRadius))
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                            .padding(homeCardInset)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.5), value: currentPet == nil)
                .animation(.easeInOut(duration: 0.5), value: isInCreationMode)

                // Floating lock button
                if currentPet != nil, !isInCreationMode, currentPet?.isBlownAway != true {
                    HomeFloatingLockButton(bottomPadding: fullScreenHeight * 0.3)
                }

                #if DEBUG
                if !isInCreationMode, !screenshotMode {
                    HomeDebugOverlay(
                        debugBumpState: $debugBumpState,
                        debugTimeOverride: $debugTimeOverride,
                        refreshTick: $refreshTick,
                        hasPet: currentPet != nil
                    )
                }

                // Triple-tap anywhere to exit screenshot mode — no overlay needed,
                // gesture is attached to the container via .simultaneousGesture below
                #endif
            }
            #if DEBUG
            .simultaneousGesture(
                TapGesture(count: 3).onEnded {
                    ScreenshotMode.shared.isActive = false
                }
            )
            #endif
            .onAppear {
                currentScreenWidth = geometry.size.width
                currentScreenHeight = geometry.size.height
                createPetCoordinator.petHeight = fullScreenHeight * 0.10
                // If pet was blown in background, set off-screen immediately
                if currentPet?.isBlownAway == true {
                    blowAwayAnimator.setBlownState(screenWidth: geometry.size.width)
                }
                // Animate card reveal on first appearance
                if currentPet != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.easeOut(duration: 0.5)) {
                            cardRevealed = true
                        }
                    }
                } else {
                    cardRevealed = true
                }
            }
            .onChange(of: geometry.size) { _, newSize in
                currentScreenWidth = newSize.width
                currentScreenHeight = newSize.height
                createPetCoordinator.petHeight = fullScreenHeight * 0.10
            }
        }
        .modifier(LegacyTabBarBackground())
        .fullScreenCover(isPresented: $showPetDetail, onDismiss: {
            if blowAwayAnimator.pendingBlowAway {
                blowAwayAnimator.pendingBlowAway = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    petManager.blowAwayCurrentPet(reason: .userChoice)
                }
            }
            if ascensionAnimator.pendingArchive, let pet = currentPet {
                ascensionAnimator.pendingArchive = false
                let petId = pet.id
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    triggerAscension(petId: petId)
                }
            }
        }) {
            if let pet = currentPet {
                PetDetailScreen(pet: pet) { action in
                    switch action {
                    case .blowAway:
                        blowAwayAnimator.pendingBlowAway = true
                        showPetDetail = false
                    case .archive:
                        ascensionAnimator.pendingArchive = true
                        showPetDetail = false
                    case .progress:
                        showPetDetail = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            if let pet = currentPet {
                                handleEvolve(pet)
                            }
                        }
                    case .replay:
                        showPetDetail = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            handleReplay()
                        }
                    default:
                        break
                    }
                }
            }
        }
        .sheet(isPresented: $showDeleteSheet) {
            if let pet = currentPet {
                DeletePetSheet(
                    petName: pet.name,
                    showArchiveOption: pet.daysSinceCreation >= PetManager.minimumArchiveDays,
                    onArchive: {
                        let petId = pet.id
                        showDeleteSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            triggerAscension(petId: petId)
                        }
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
                    onArchive: {
                        let petId = pet.id
                        showSuccessArchivePrompt = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            triggerAscension(petId: petId)
                        }
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
        .sheet(isPresented: $petManager.needsAppReselection) {
            if let pet = petManager.currentPet {
                RestoreAppReselectionSheet(
                    petName: pet.name,
                    canArchive: pet.daysSinceCreation >= PetManager.minimumArchiveDays
                ) { action in
                    switch action {
                    case .reauthorize:
                        try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    case .save(let selection):
                        let sources = LimitedSource.from(selection)
                        petManager.handleAppReselectionComplete(sources, selection: selection)
                    case .archive:
                        petManager.handleAppReselectionExhausted(action: .archive, using: archivedPetManager)
                    case .delete:
                        petManager.handleAppReselectionExhausted(action: .delete)
                    }
                }
            }
        }
        .sheet(isPresented: $showEvolutionUpsell) {
            EvolutionUpsellSheet(petName: currentPet?.name ?? "Your Uuumi") {
                pendingEvolveAction?()
                pendingEvolveAction = nil
            }
        }
        .sheet(isPresented: $showEssenceUpsell) {
            EssenceApplicationUpsellSheet(petName: currentPet?.name ?? "Your Uuumi") {
                pendingEssenceAction?()
                pendingEssenceAction = nil
            }
        }
        .premiumSheet(isPresented: $showPremiumSheet, source: .petCreated)
        .windNotCalmSheet(isPresented: $showWindNotCalmAlert)
        .alert(
            "Screen Time Access",
            isPresented: $showAuthorizationAlert
        ) {
            Button("OK") {}
        } message: {
            Text("To create a pet, you need to allow Screen Time access in Settings.")
        }
        .onAppear {
            windRhythm.start()
            windRhythm.paused = (currentPet?.windLevel == .none || currentPet == nil)
            // Force immediate refresh to read latest wind from SharedDefaults
            refreshTick += 1
            configureRefreshTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateHome)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                reactionAnimator.playRandom()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .selectPet)) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                reactionAnimator.playRandom()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Force refresh when returning from background to read latest wind
            refreshTick += 1
            configureRefreshTimer()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            // Dismiss upsell sheets to prevent stale state (wind may change in background)
            showEvolutionUpsell = false
            showEssenceUpsell = false
            pendingEvolveAction = nil
            pendingEssenceAction = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .windDidReset)) { _ in
            refreshTick += 1
        }
        .onDisappear {
            windRhythm.stop()
            refreshTimer?.invalidate()
            refreshTimer = nil
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
        .onChange(of: coinsAnimator.phase) { _, newPhase in
            if newPhase == .burst {
                reactionAnimator.playRandom()
            }
        }
        .onChange(of: currentPet?.id) { _, _ in
            // Reset animators when pet changes (e.g. deleted + new pet created)
            blowAwayAnimator.reset()
            ascensionAnimator.reset()
            evolutionAnimator.reset()
        }
        .onChange(of: currentPet?.isBlownAway) { oldValue, newValue in
            if newValue == true && oldValue != true, let screenWidth = currentScreenWidth {
                blowAwayAnimator.trigger(screenWidth: screenWidth)
                if let pet = currentPet {
                    analytics.send(.blowAway(essence: pet.evolutionTypeName, phase: pet.currentPhase, days: pet.totalDays))
                }
            }
        }
        .onChange(of: currentPet?.windLevel) { _, newLevel in
            windRhythm.paused = (newLevel == .none || newLevel == nil)
            configureRefreshTimer()
        }
        .onChange(of: ShieldState.shared.isActive) { _, _ in
            refreshTick += 1
        }
    }

    // MARK: - Shared Island

    @ViewBuilder
    private func islandView(geometry: GeometryProxy) -> some View {
        if let pet = currentPet, !isInCreationMode {
            // Force recalculation when refreshTick changes
            let _ = refreshTick
            let effectiveProgress = pet.windProgress

            IslandView(
                screenHeight: fullScreenHeight,
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
                archiveOffsetY: ascensionAnimator.petOffsetY,
                archiveStretchAmount: ascensionAnimator.stretchAmount,
                archiveGlowRadius: ascensionAnimator.glowRadius,
                isAscending: ascensionAnimator.isAnimating,
                showEssenceDropZone: essenceCoordinator.hasSelectedEssence,
                isEssenceHighlighted: isEssenceDropZoneHighlighted,
                isEssenceOnTarget: isEssenceOnTarget,
                isEvolutionTransitioning: evolutionAnimator.isShowingTransition,
                reactionAnimator: reactionAnimator,
                transitionContent: {
                    if evolutionAnimator.isShowingTransition {
                        EvolutionTransitionView(
                            isActive: true,
                            config: evolutionAnimator.transitionConfig,
                            particleConfig: evolutionAnimator.particleConfig,
                            oldAssetName: evolutionAnimator.oldAssetName,
                            newAssetName: evolutionAnimator.newAssetName,
                            oldEyesAssetName: evolutionAnimator.oldEyesAssetName,
                            newEyesAssetName: evolutionAnimator.newEyesAssetName,
                            oldScale: evolutionAnimator.oldScale,
                            newScale: evolutionAnimator.newScale,
                            cameraTransform: .init(
                                get: { evolutionAnimator.cameraTransform },
                                set: { evolutionAnimator.cameraTransform = $0 }
                            ),
                            onComplete: {
                                evolutionAnimator.complete()
                                petManager.savePet()
                                coinsAnimator.showReward(CoinRewards.forEvolution(isPremium: SharedDefaults.isPremiumCached))
                                ScheduledNotificationManager.refresh(
                                    isEvolutionAvailable: pet.isEvolutionAvailable,
                                    hasPet: true,
                                    nextEvolutionUnlockDate: pet.evolutionHistory.nextEvolutionUnlockDate
                                )
                                Task { await syncManager.syncUserData(essenceCatalogManager: essenceCatalogManager) }
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
        } else {
            IslandView(
                screenHeight: fullScreenHeight,
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
        }
    }

    // MARK: - Pet Overlays (wind lines, replay)

    private func petOverlays(_ pet: Pet, geometry: GeometryProxy) -> some View {
        let _ = refreshTick
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

            ReplayOverlayView(isVisible: blowAwayAnimator.replayOverlayVisible, petFrame: petFrame)
        }
    }

    // MARK: - Empty Island Card

    private var emptyIslandCard: some View {
        EmptyIslandCard {
            await requestAuthorizationAndCreatePet()
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
            withAnimation(.easeInOut(duration: 0.5)) {
                createPetCoordinator.show { [storeManager] _ in
                    reactionAnimator.playRandom(withGlow: true)
                    if !storeManager.isPremium {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showPremiumSheet = true
                        }
                    }
                }
            }
            return
        }

        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            withAnimation(.easeInOut(duration: 0.5)) {
                createPetCoordinator.show { [storeManager] _ in
                    reactionAnimator.playRandom(withGlow: true)
                    if !storeManager.isPremium {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showPremiumSheet = true
                        }
                    }
                }
            }
        } catch {
            showAuthorizationAlert = true
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
            hideBump: ascensionAnimator.isAnimating,
            onAction: { handleAction($0, for: pet) }
        )
        #else
        HomeCardView(
            pet: pet,
            streakCount: pet.totalDays,
            showDetailButton: true,
            windProgress: windProgress,
            hideBump: ascensionAnimator.isAnimating,
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

    // MARK: - Archive Ascension

    private func triggerAscension(petId: UUID) {
        guard !ascensionAnimator.isAnimating else { return }

        if let pet = currentPet {
            let reason = pet.isFullyEvolved ? "completed" : "manual"
            analytics.send(.petArchived(essence: pet.evolutionTypeName, phase: pet.currentPhase, days: pet.totalDays, reason: reason))

            // Pet is not visually on the island — skip ascension animation
            if pet.isBlownAway {
                petManager.archive(id: petId, using: archivedPetManager)
                return
            }
        }

        let screenHeight = fullScreenHeight > 0 ? fullScreenHeight : 800
        ascensionAnimator.trigger(screenHeight: screenHeight) { [petManager, archivedPetManager] in
            // Archive without animation — pet is already off-screen.
            // The empty island card slides in via its own transition.
            // Cloud sync (archive + delete active) is handled internally by PetManager.
            petManager.archive(id: petId, using: archivedPetManager)
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
                let evolveAction = {
                    analytics.send(.essenceApplied(essence: essence.name))
                    evolutionAnimator.triggerEssenceApplication(pet: pet, essence: essence)
                }
                if storeManager.isPremium {
                    evolveAction()
                } else {
                    pendingEssenceAction = evolveAction
                    showEssenceUpsell = true
                }
            }
        } else {
            let evolveAction = {
                analytics.send(.petEvolved(essence: pet.evolutionTypeName, phase: pet.currentPhase + 1))
                evolutionAnimator.trigger(pet: pet)
            }
            if storeManager.isPremium {
                evolveAction()
            } else {
                pendingEvolveAction = evolveAction
                showEvolutionUpsell = true
            }
        }
    }

    // MARK: - Refresh Timer

    /// Configures 1s refresh timer for real-time wind and UI updates.
    private func configureRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                refreshTick += 1
            }
        }
    }

}

// MARK: - LegacyTabBarBackground

/// Forces a visible tab bar background on iOS < 26 where automatic liquid glass is unavailable.
/// HomeScreen has no ScrollView, so the system tab bar stays transparent by default.
private struct LegacyTabBarBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
        } else {
            content
                .toolbarBackground(.ultraThinMaterial, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
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

#Preview {
    HomeScreen()
        .environment(PetManager.mock())
        .environment(ArchivedPetManager.mock())
        .environment(EssencePickerCoordinator())
        .environment(CreatePetCoordinator())
        .environment(CoinsRewardAnimator())
        .environment(StoreManager.mock())
}
