import SwiftUI

/// Main home screen displaying the floating island scene with pet and status card.
struct HomeScreen: View {
    @Environment(\.colorScheme) private var colorScheme

    /// Shared wind rhythm for synchronized effects between pet animation and wind lines
    @State private var windRhythm = WindRhythm()
    @State private var showPetDetail = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background (day/night based on color scheme)
                if colorScheme == .dark {
                    NightBackgroundView()
                } else {
                    DayBackgroundView()
                }

                // Wind lines effect (scales with wind level)
                // Wind area centered around pet (0.25-0.50 = matches PetDebugView)
                WindLinesView(
                    windLevel: .high,
                    direction: 1.0,
                    windAreaTop: 0.25,
                    windAreaBottom: 0.50,
                    windRhythm: windRhythm
                )

                // Floating island with pet
                FloatingIslandView(
                    screenHeight: geometry.size.height,
                    screenWidth: geometry.size.width,
                    pet: Essence.plant.phase(at: 4)!,
                    windLevel: .high,
                    windDirection: 1.0,
                    windRhythm: windRhythm
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.container, edges: .bottom)

                // Status card
                StatusCardContentView(
                    streakCount: 19,
                    usedTimeText: "32m",
                    dailyLimitText: "2h",
                    progress: 0.27,
                    petName: "Fern",
                    evolutionStage: 2,
                    maxEvolutionStage: 4,
                    mood: .happy,
                    purposeLabel: "Social Media",
                    isEvolutionAvailable: false,
                    daysUntilEvolution: 1,
                    isSaveEnabled: true,
                    showDetailButton: true,
                    isBlownAway: false,
                    onDetailTapped: { showPetDetail = true }
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(16)
            }
        }
        .fullScreenCover(isPresented: $showPetDetail) {
            PetActiveDetailScreen(
                petName: "Fern",
                evolutionHistory: EvolutionHistory(
                    createdAt: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
                    essence: .plant,
                    events: [
                        EvolutionEvent(
                            fromPhase: 1,
                            toPhase: 2,
                            date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                        )
                    ]
                ),
                streak: 19,
                purposeLabel: "Social Media",
                windLevel: .high,
                isBlownAway: false,
                usedMinutes: 32,
                limitMinutes: 120,
                weeklyStats: .mock(),
                blockedAppCount: 12
            )
        }
        .onAppear {
            windRhythm.start()
        }
        .onDisappear {
            windRhythm.stop()
        }
    }
}

#Preview {
    HomeScreen()
}
