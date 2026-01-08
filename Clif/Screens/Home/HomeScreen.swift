import SwiftUI

/// Main home screen displaying the floating island scene with pet and status card.
struct HomeScreen: View {
    @Environment(\.colorScheme) private var colorScheme

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
                WindLinesView(windLevel: .low)

                // Floating island with pet
                FloatingIslandView(
                    screenHeight: geometry.size.height,
                    evolution: PlantEvolution.phase1,
                    windLevel: .low
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
