import SwiftUI

struct OnboardingView: View {
    @AppStorage(DefaultsKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false

    @Environment(\.colorScheme) private var colorScheme
    @State private var currentScreen: OnboardingScreen = .island

    var body: some View {
        ZStack {
            onboardingBackground

            TabView(selection: $currentScreen) {
                ForEach(OnboardingScreen.allCases) { screen in
                    Group {
                        switch screen {
                        case .island:
                            OnboardingIslandStep()
                        default:
                            OnboardingPlaceholderStep(screen: screen)
                        }
                    }
                    .tag(screen)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(.container, edges: .bottom)
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

    @ViewBuilder
    private var onboardingBackground: some View {
        switch colorScheme {
        case .dark:
            NightBackgroundView()
        default:
            DayBackgroundView()
        }
    }

    private var continueButton: some View {
        Button {
            HapticType.impactLight.trigger()
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
