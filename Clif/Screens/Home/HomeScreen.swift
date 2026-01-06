import SwiftUI

struct HomeScreen: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if colorScheme == .dark {
                    NightBackgroundView()
                } else {
                    DayBackgroundView()
                }

                CliffView(screenHeight: geometry.size.height)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(.container, edges: .bottom)

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
