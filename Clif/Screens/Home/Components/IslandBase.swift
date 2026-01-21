import SwiftUI

/// Base island component with rock and grass.
/// Used by both IslandView and EmptyIslandView to ensure consistent positioning.
struct IslandBase: View {
    let screenHeight: CGFloat

    var islandHeight: CGFloat { screenHeight * 0.6 }

    var body: some View {
        Image("rock")
            .resizable()
            .scaledToFit()
            .frame(maxHeight: islandHeight)
            .overlay(alignment: .top) {
                Image("grass")
                    .resizable()
                    .scaledToFit()
            }
    }
}

#if DEBUG
#Preview {
    GeometryReader { geometry in
        ZStack {
            Color.blue.opacity(0.3)
            IslandBase(screenHeight: geometry.size.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        }
        .ignoresSafeArea()
    }
}
#endif
