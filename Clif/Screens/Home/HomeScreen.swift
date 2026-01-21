import SwiftUI

/// Main home screen displaying the floating island scene with pet and status card.
/// Supports horizontal paging when multiple pets exist.
struct HomeScreen: View {
    @Environment(PetManager.self) private var petManager
    @Environment(EssencePickerCoordinator.self) private var essenceCoordinator
    @Environment(CreatePetCoordinator.self) private var createPetCoordinator
    @Environment(\.colorScheme) private var colorScheme

    @State private var windRhythm = WindRhythm()
    @State private var selectedPetId: UUID?
    @State private var showPetDetail = false
    @State private var showBreakSheet = false
    @State private var petFrame: CGRect = .zero
    @State private var dropZoneFrame: CGRect = .zero

    private let homeCardInset: CGFloat = 16
    private let homeCardCornerRadius: CGFloat = 24

    /// Whether we're in pet creation mode (empty island shown during entire flow)
    private var isInCreationMode: Bool {
        createPetCoordinator.isShowing || createPetCoordinator.isDropping
    }

    /// Whether the dragged pet is near the drop zone
    private var isDropZoneHighlighted: Bool {
        guard createPetCoordinator.dragState.isDragging,
              dropZoneFrame != .zero else { return false }
        let expandedFrame = dropZoneFrame.insetBy(dx: -60, dy: -60)
        return expandedFrame.contains(createPetCoordinator.dragState.dragLocation)
    }

    private var pets: [ActivePet] { petManager.activePets }

    private var currentPet: ActivePet? {
        if let selectedPetId {
            return pets.first { $0.id == selectedPetId }
        }
        return pets.first
    }

    private var petDropFrame: CGRect? {
        // Use drop zone frame during creation, pet frame otherwise
        let frame = isInCreationMode ? dropZoneFrame : petFrame
        guard frame != .zero else { return nil }
        return frame.insetBy(dx: -40, dy: -40)
    }

    private func updatePetDropFrame() {
        createPetCoordinator.petDropFrame = petDropFrame
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                background

                if isInCreationMode {
                    // Show empty island with drop zone during pet creation
                    emptyIslandPage(geometry: geometry)
                } else if pets.count > 1 {
                    petPager(geometry: geometry)
                } else if let pet = currentPet {
                    petPage(pet, geometry: geometry)
                }
            }
        }
        .fullScreenCover(isPresented: $showPetDetail) {
            if let pet = currentPet {
                petDetailScreen(for: pet)
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
        EmptyIslandView(
            screenHeight: geometry.size.height,
            isDropZoneHighlighted: isDropZoneHighlighted,
            onDropZoneFrameChange: { frame in
                dropZoneFrame = frame
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: - Pet Pager

    private func petPager(geometry: GeometryProxy) -> some View {
        TabView(selection: $selectedPetId) {
            ForEach(pets) { pet in
                petPage(pet, geometry: geometry)
                    .tag(pet.id as UUID?)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .onAppear {
            if selectedPetId == nil {
                selectedPetId = pets.first?.id
            }
        }
    }

    // MARK: - Single Pet Page

    private func petPage(_ pet: ActivePet, geometry: GeometryProxy) -> some View {
        ZStack {
            WindLinesView(
                windProgress: pet.windProgress,
                direction: 1.0,
                windAreaTop: 0.25,
                windAreaBottom: 0.50,
                windRhythm: windRhythm
            )

            FloatingIslandView(
                screenHeight: geometry.size.height,
                screenWidth: geometry.size.width,
                pet: pet.phase ?? Blob.shared,
                windProgress: pet.windProgress,
                windDirection: 1.0,
                windRhythm: windRhythm,
                onPetFrameChange: { frame in
                    petFrame = frame
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(.container, edges: .bottom)

            homeCard(for: pet)
                .modifier(HomeCardBackgroundModifier(cornerRadius: homeCardCornerRadius))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(homeCardInset)
        }
    }

    // MARK: - Home Card

    private func homeCard(for pet: ActivePet) -> some View {
        HomeCardView(
            pet: pet,
            streakCount: 7, // TODO: get from streak manager
            showDetailButton: true,
            onAction: { handleAction($0, for: pet) }
        )
    }

    private func handleAction(_ action: HomeCardAction, for pet: ActivePet) {
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

    // MARK: - Detail Screen

    @ViewBuilder
    private func petDetailScreen(for pet: ActivePet) -> some View {
        switch pet {
        case .daily(let dailyPet):
            DailyPetDetailScreen(pet: dailyPet)
        case .dynamic(let dynamicPet):
            DynamicPetDetailScreen(pet: dynamicPet)
        }
    }

    // MARK: - Actions

    private func handleEvolve(_ pet: ActivePet) {
        if pet.isBlob {
            essenceCoordinator.show(petDropFrame: petDropFrame) { essence in
                pet.applyEssence(essence)
            }
        } else {
            pet.evolve()
        }
    }

    private func handleBreak(_ pet: ActivePet) {
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
