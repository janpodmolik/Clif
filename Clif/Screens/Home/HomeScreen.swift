import Combine
import SwiftUI

/// Main home screen displaying the floating island scene with pet and status card.
/// Supports horizontal paging when multiple pets exist.
struct HomeScreen: View {
    @Environment(PetManager.self) private var petManager
    @Environment(ArchivedPetManager.self) private var archivedPetManager
    @Environment(EssencePickerCoordinator.self) private var essenceCoordinator
    @Environment(CreatePetCoordinator.self) private var createPetCoordinator
    @Environment(\.colorScheme) private var colorScheme

    @State private var windRhythm = WindRhythm()
    @State private var blowAwayAnimator = BlowAwayAnimator()
    @State private var currentScreenWidth: CGFloat?
    @State private var showPetDetail = false
    @State private var showPresetPicker = false
    @State private var showDeleteSheet = false
    @State private var showSuccessArchivePrompt = false
    @State private var petFrame: CGRect = .zero
    @State private var dropZoneFrame: CGRect = .zero

    /// Timer-driven refresh trigger for real-time wind updates during active shield.
    /// Increments every second to force UI recalculation of effectiveWindPoints.
    @State private var refreshTick = 0

    #if DEBUG
    /// Debug state for testing bump visibility (evolve/blown buttons)
    @State private var debugBumpState: DebugBumpState = .actual
    #endif

    private let homeCardInset: CGFloat = 16

    /// Concentric corner radius for the card (based on screen edge distance)
    private var homeCardCornerRadius: CGFloat {
        DeviceMetrics.concentricCornerRadius(inset: homeCardInset)
    }
    private let dropTargetExpansion: CGFloat = 40

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

    private var currentPet: Pet? { petManager.currentPet }

    private var petDropFrame: CGRect? {
        // Use drop zone frame during creation, pet frame otherwise
        let frame = isInCreationMode ? dropZoneFrame : petFrame
        guard frame != .zero else { return nil }
        return frame.insetBy(dx: -dropTargetExpansion, dy: -dropTargetExpansion)
    }

    private func updatePetDropFrame() {
        createPetCoordinator.petDropFrame = petDropFrame
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                background

                if isInCreationMode || currentPet == nil {
                    // Show empty island during pet creation or when no pet exists
                    emptyIslandPage(geometry: geometry)
                } else if let pet = currentPet {
                    petPage(pet, geometry: geometry)
                }
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
        }) {
            if let pet = currentPet {
                PetDetailScreen(pet: pet) { action in
                    switch action {
                    case .blowAway:
                        blowAwayAnimator.pendingBlowAway = true
                        showPetDetail = false
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
                    showArchiveOption: pet.daysSinceCreation >= 3,
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
        }
        .onChange(of: dropZoneFrame) { _, _ in
            updatePetDropFrame()
        }
        .onChange(of: isInCreationMode) { _, _ in
            updatePetDropFrame()
        }
        .onChange(of: currentPet?.id) { _, _ in
            // Reset animator when pet changes (e.g. deleted + new pet created)
            blowAwayAnimator.reset()
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
        if colorScheme == .dark {
            NightBackgroundView()
        } else {
            DayBackgroundView()
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
                        isSnapped: createPetCoordinator.dragState.isSnapped,
                        isVisible: true
                    )
                    : .dropZone(isHighlighted: false, isSnapped: false, isVisible: false),
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
            createPetCoordinator.show { _ in }
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
                onFrameChange: { frame in
                    petFrame = frame
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(.container, edges: .bottom)

            homeCard(for: pet, windProgress: effectiveProgress)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(homeCardInset)

            ReplayOverlayView(isVisible: blowAwayAnimator.replayOverlayVisible, petFrame: petFrame)

            #if DEBUG
            debugBumpToggle
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(homeCardInset)

//            EventLogOverlay()
//                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            #endif
        }
    }


    // MARK: - Home Card

    private func homeCard(for pet: Pet, windProgress: CGFloat) -> some View {
        #if DEBUG
        HomeCardView(
            pet: pet,
            streakCount: 7, // TODO: get from streak manager
            showDetailButton: true,
            windProgress: windProgress,
            debugBumpState: debugBumpState,
            onAction: { handleAction($0, for: pet) }
        )
        #else
        HomeCardView(
            pet: pet,
            streakCount: 7, // TODO: get from streak manager
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
            handleEvolve(pet)
        case .replay:
            handleReplay()
        case .delete:
            showDeleteSheet = true
        case .archive:
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
            essenceCoordinator.show(petDropFrame: petDropFrame) { essence in
                pet.applyEssence(essence)
            }
        } else {
            pet.evolve()
            if pet.isFullyEvolved {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    showSuccessArchivePrompt = true
                }
            }
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
}
#endif

#Preview {
    HomeScreen()
        .environment(PetManager.mock())
        .environment(ArchivedPetManager.mock())
        .environment(EssencePickerCoordinator())
        .environment(CreatePetCoordinator())
}
