import SwiftUI

struct DayBackgroundView: View {
    var theme: DayTheme = .morningHaze

    var body: some View {
        LinearGradient(
            colors: theme.gradient,
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview("Morning Haze") {
    DayBackgroundView(theme: .morningHaze)
}

#Preview("Clear Sky") {
    DayBackgroundView(theme: .clearSky)
}
