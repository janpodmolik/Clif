import SwiftUI

/// Main home screen displaying the floating island scene with pet and status card.
struct HomeScreen: View {
    @Environment(\.colorScheme) private var colorScheme

    private let windDirection = WindDirection.forToday()

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
                // Wind area behind and above the pet (0.25-0.50 = upper-middle of screen)
                WindLinesView(
                    windLevel: .high,
                    direction: windDirection,
                    windAreaTop: 0.25,
                    windAreaBottom: 0.50
                )

                // Floating island with pet
                FloatingIslandView(
                    screenHeight: geometry.size.height,
                    screenWidth: geometry.size.width,
                    evolution: PlantEvolution.phase4,
                    windLevel: .high,
                    windDirection: windDirection
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.container, edges: .bottom)

                // Status card
                StatusCardContentView(
                    streakCount: 19,
                    usedTimeText: "32m",
                    dailyLimitText: "2h",
                    progress: 0.27
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(16)
            }
        }
    }
}

#Preview {
    HomeScreen()
}
