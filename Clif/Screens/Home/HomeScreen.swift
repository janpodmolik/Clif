import SwiftUI

struct HomeScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var menuProgress: CGFloat = 0

    private let animation: Animation = .smooth(duration: 0.55, extraBounce: 0.05)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if colorScheme == .dark {
                    NightBackgroundView()
                } else {
                    DayBackgroundView()
                }

                Image("home")
                    .resizable()
                    .scaledToFit()
                    .frame(height: geometry.size.height * 0.8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(.container, edges: .bottom)
                    .onTapGesture {
                        withAnimation(animation) {
                            menuProgress = 0
                        }
                    }

                ExpandableGlassMenu(
                    alignment: .topTrailing,
                    progress: menuProgress,
                    expandedWidth: geometry.size.width - 32
                ) {
                    StatusCardContentView(
                        streakCount: 19,
                        usedTimeText: "32m",
                        dailyLimitText: "2h",
                        progress: 0.27
                    )
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 20))
                        .frame(width: 56, height: 56)
                        .contentShape(.rect)
                        .onTapGesture {
                            withAnimation(animation) {
                                menuProgress = menuProgress == 0 ? 1 : 0
                            }
                        }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(16)
            }
        }
    }
}

#Preview {
    HomeScreen()
}
