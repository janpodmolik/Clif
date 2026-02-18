import SwiftUI

struct OnboardingView: View {
    @AppStorage(DefaultsKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false

    @State private var currentScreen: OnboardingScreen = .island

    var body: some View {
        ZStack {
            TabView(selection: $currentScreen) {
                ForEach(OnboardingScreen.allCases) { screen in
                    OnboardingPlaceholderStep(screen: screen)
                        .tag(screen)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentScreen)

            VStack {
                StepIndicator(
                    currentStep: currentScreen.rawValue,
                    totalSteps: OnboardingScreen.totalCount
                )
                .padding(.top, 12)

                Spacer()

                continueButton
                    .padding(.horizontal, 24)
            }
        }
    }

    private var continueButton: some View {
        Button {
            if currentScreen.isLast {
                hasCompletedOnboarding = true
            } else if let next = currentScreen.next {
                currentScreen = next
            }
        } label: {
            Text(currentScreen.isLast ? "Start" : "Continue")
        }
        .buttonStyle(.primary)
    }
}

#if DEBUG
#Preview {
    OnboardingView()
}
#endif
