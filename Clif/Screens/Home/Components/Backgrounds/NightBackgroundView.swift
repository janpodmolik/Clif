import SwiftUI

struct NightBackgroundView: View {
    var theme: NightTheme = .deepNight

    var body: some View {
        ZStack {
            LinearGradient(
                colors: theme.gradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            StarCanvasView()
        }
    }
}

#Preview("Deep Night") {
    NightBackgroundView(theme: .deepNight)
}

#Preview("Twilight") {
    NightBackgroundView(theme: .twilight)
}
