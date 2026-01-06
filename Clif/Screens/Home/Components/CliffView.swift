import SwiftUI

struct CliffView: View {
    let screenHeight: CGFloat

    private var cliffHeight: CGFloat { screenHeight * 0.6 }
    private var petHeight: CGFloat { screenHeight * 0.15 }
    private var petOffset: CGFloat { -petHeight * 0.65 }

    var body: some View {
        Image("rock")
            .resizable()
            .scaledToFit()
            .frame(maxHeight: cliffHeight)
            .overlay(alignment: .top) {
                Image("grass")
                    .resizable()
                    .scaledToFit()
                    .overlay(alignment: .top) {
                        Image("plant-1")
                            .resizable()
                            .scaledToFit()
                            .frame(height: petHeight)
                            .offset(y: petOffset)
                    }
            }
    }
}

#Preview {
    GeometryReader { geometry in
        CliffView(screenHeight: geometry.size.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
    .background(Color.blue.opacity(0.3))
}
