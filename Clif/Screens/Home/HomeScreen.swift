import SwiftUI

/// Main home screen displaying the floating island scene with pet and status card.
struct HomeScreen: View {
    @Environment(PetManager.self) private var petManager
    @Environment(EssencePickerCoordinator.self) private var essenceCoordinator
    @Environment(\.colorScheme) private var colorScheme

    /// Shared wind rhythm for synchronized effects between pet animation and wind lines
    @State private var windRhythm = WindRhythm()
    @State private var showPetDetail = false
    @State private var petFrame: CGRect = .zero

    private let homeCardInset: CGFloat = 16

    private var pet: ActivePet? { petManager.currentPet }
    private var petDropFrame: CGRect? {
        guard petFrame != .zero else { return nil }
        return petFrame.insetBy(dx: -40, dy: -40)
    }

    private let homeCardCornerRadius: CGFloat = 24

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background (day/night based on color scheme)
                if colorScheme == .dark {
                    NightBackgroundView()
                } else {
                    DayBackgroundView()
                }

                if let pet {
                    // Wind lines effect (scales with usage progress)
                    WindLinesView(
                        windProgress: pet.windProgress,
                        direction: 1.0,
                        windAreaTop: 0.25,
                        windAreaBottom: 0.50,
                        windRhythm: windRhythm
                    )

                    // Floating island with pet
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

                    // Home card
                    homeCard(for: pet)
                        .modifier(HomeCardBackgroundModifier(cornerRadius: homeCardCornerRadius))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(homeCardInset)
                }
            }
        }
        .fullScreenCover(isPresented: $showPetDetail) {
            if let pet {
                PetActiveDetailScreen(pet: pet)
            }
        }
        .onAppear {
            windRhythm.start()
        }
        .onDisappear {
            windRhythm.stop()
        }
    }

    private func homeCard(for pet: ActivePet) -> some View {
        HomeCardContentView(
            streakCount: 7, // TODO: get from streak manager
            usedTimeText: formatMinutes(pet.todayUsedMinutes),
            dailyLimitText: formatMinutes(pet.dailyLimitMinutes),
            progress: Double(pet.windProgress),
            petName: pet.name,
            evolutionStage: pet.currentPhase,
            maxEvolutionStage: pet.evolutionHistory.maxPhase,
            mood: Mood(from: pet.windLevel),
            purposeLabel: pet.purpose,
            isEvolutionAvailable: pet.isBlob ? pet.canUseEssence : pet.canEvolve,
            daysUntilEvolution: pet.isBlob ? pet.daysUntilEssence : pet.daysUntilEvolution,
            isSaveEnabled: false,
            showDetailButton: true,
            isBlownAway: pet.isBlown,
            onDetailTapped: { showPetDetail = true },
            onEvolveTapped: {
                if pet.isBlob {
                    essenceCoordinator.show(petDropFrame: petDropFrame) { essence in
                        pet.applyEssence(essence)
                    }
                } else {
                    pet.evolve()
                }
            },
            onBlowAwayTapped: {
                #if DEBUG
                NotificationCenter.default.post(name: .showMockSheet, object: nil)
                #endif
            }
        )
    }

    private func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"
        }
        return "\(mins)m"
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
}
