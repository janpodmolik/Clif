import SwiftUI

/// Main home screen displaying the floating island scene with pet and status card.
struct HomeScreen: View {
    @Environment(PetManager.self) private var petManager
    @Environment(\.colorScheme) private var colorScheme

    /// Shared wind rhythm for synchronized effects between pet animation and wind lines
    @State private var windRhythm = WindRhythm()
    @State private var showPetDetail = false
    @State private var showEssencePicker = false
    @State private var petFrame: CGRect = .zero

    private var pet: ActivePet? { petManager.currentPet }
    private var petDropFrame: CGRect? {
        guard petFrame != .zero else { return nil }
        return petFrame.insetBy(dx: -40, dy: -40)
    }

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
                    // Wind lines effect (scales with wind level)
                    WindLinesView(
                        windLevel: pet.windLevel,
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
                        windLevel: pet.windLevel,
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
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(16)
                }
            }
        }
        .fullScreenCover(isPresented: $showPetDetail) {
            if let pet {
                PetActiveDetailScreen(pet: pet)
            }
        }
        .sheet(isPresented: $showEssencePicker) {
            EssencePickerTray(
                petDropFrame: petDropFrame,
                onDropOnPet: { essence in
                    guard let pet else { return }
                    pet.applyEssence(essence)
                    showEssencePicker = false
                },
                onClose: { showEssencePicker = false }
            )
                .presentationDetents([.height(200)])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .height(200)))
        }
        .onAppear {
            windRhythm.start()
        }
        .onDisappear {
            windRhythm.stop()
        }
    }

    private func homeCard(for pet: ActivePet) -> some View {
        let progress = pet.dailyLimitMinutes > 0
            ? Double(pet.todayUsedMinutes) / Double(pet.dailyLimitMinutes)
            : 0

        return HomeCardContentView(
            streakCount: 7, // TODO: get from streak manager
            usedTimeText: formatMinutes(pet.todayUsedMinutes),
            dailyLimitText: formatMinutes(pet.dailyLimitMinutes),
            progress: progress,
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
                    showEssencePicker = true
                } else {
                    pet.evolve()
                }
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

#Preview {
    HomeScreen()
        .environment(PetManager.mock())
}
