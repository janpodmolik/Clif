import SwiftUI

struct DayBackgroundView: View {
    private let gradient = LinearGradient(
        colors: [
            Color(red: 0.68, green: 0.75, blue: 0.85),
            Color(red: 0.78, green: 0.80, blue: 0.85),
            Color(red: 0.90, green: 0.85, blue: 0.82),
            Color(red: 0.93, green: 0.82, blue: 0.75)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        gradient
            .ignoresSafeArea()
    }
}

#Preview {
    DayBackgroundView()
}
