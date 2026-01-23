import SwiftUI

/// Main home screen displaying the floating island scene with pet and status card.
/// Supports horizontal paging when multiple pets exist.
struct HomeScreen: View {
    @Environment(PetManager.self) private var petManager
    @Environment(EssencePickerCoordinator.self) private var essenceCoordinator
    @Environment(CreatePetCoordinator.self) private var createPetCoordinator
    @Environment(\.colorScheme) private var colorScheme

    @State private var windRhythm = WindRhythm()
    @State private var showPetDetail = false
    @State private var showBreakSheet = false
    @State private var petFrame: CGRect = .zero
    @State private var dropZoneFrame: CGRect = .zero

    private let homeCardInset: CGFloat = 16
    private let homeCardCornerRadius: CGFloat = 24
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
        }
        .fullScreenCover(isPresented: $showPetDetail) {
            if let pet = currentPet {
                PetDetailScreen(pet: pet)
            }
        }
        .sheet(isPresented: $showBreakSheet) {
            // TODO: Replace with BreakSheet
            Text("Break Sheet - Coming Soon")
                .presentationDetents([.medium])
        }
        .onAppear {
            windRhythm.start()
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
        ZStack {
            WindLinesView(
                windProgress: pet.windProgress,
                direction: 1.0,
                windAreaTop: 0.25,
                windAreaBottom: 0.50,
                windRhythm: windRhythm
            )

            IslandView(
                screenHeight: geometry.size.height,
                screenWidth: geometry.size.width,
                content: .pet(
                    pet.phase ?? Blob.shared,
                    windProgress: pet.windProgress,
                    windDirection: 1.0,
                    windRhythm: windRhythm
                ),
                onFrameChange: { frame in
                    petFrame = frame
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(.container, edges: .bottom)

            homeCard(for: pet)
                .modifier(HomeCardBackgroundModifier(cornerRadius: homeCardCornerRadius))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(homeCardInset)

            #if DEBUG
            debugWindOverlay(pet)
            #endif
        }
    }

    #if DEBUG
    private func debugWindOverlay(_ pet: Pet) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Wind: \(String(format: "%.1f", pet.windPoints)) pts")
            Text("Last threshold: \(pet.lastThresholdSeconds)s")
            Text("Rise rate: \(String(format: "%.1f", pet.preset.riseRate)) pts/min")
        }
        .font(.system(size: 10, design: .monospaced))
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        .padding(.leading, 16)
        .padding(.bottom, 200)
    }
    #endif

    // MARK: - Home Card

    private func homeCard(for pet: Pet) -> some View {
        HomeCardView(
            pet: pet,
            streakCount: 7, // TODO: get from streak manager
            showDetailButton: true,
            onAction: { handleAction($0, for: pet) }
        )
    }

    private func handleAction(_ action: HomeCardAction, for pet: Pet) {
        switch action {
        case .detail:
            showPetDetail = true
        case .evolve:
            handleEvolve(pet)
        case .replay, .delete:
            break // TODO: Handle archived pet actions
        case .startBreak:
            handleBreak(pet)
        }
    }

    // MARK: - Actions

    private func handleEvolve(_ pet: Pet) {
        if pet.isBlob {
            essenceCoordinator.show(petDropFrame: petDropFrame) { essence in
                pet.applyEssence(essence)
            }
        } else {
            pet.evolve()
        }
    }

    private func handleBreak(_ pet: Pet) {
        showBreakSheet = true
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
        .environment(EssencePickerCoordinator())
        .environment(CreatePetCoordinator())
}
