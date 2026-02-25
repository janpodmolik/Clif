import SwiftUI

struct OnboardingBackgroundView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        switch colorScheme {
        case .dark:
            NightBackgroundView()
        default:
            DayBackgroundView()
        }
    }
}
