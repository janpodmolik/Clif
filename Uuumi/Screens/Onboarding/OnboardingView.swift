import SwiftUI

struct OnboardingView: View {
    @AppStorage(DefaultsKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false

    @State private var currentScreen: OnboardingScreen = .island
    @State private var visitedScreens: Set<OnboardingScreen> = []

    // Island state — driven by steps via bindings
    @State private var showBlob = false
    @State private var windProgress: CGFloat = 0
    @State private var eyesOverride: String? = nil
    @State private var onPetTap: (() -> Void)?

    // Speech bubble state — controlled by steps
    @State private var speechBubbleConfig: SpeechBubbleConfig? = nil
    @State private var speechBubbleVisible = false
    @State private var showTapHint = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                OnboardingBackgroundView()

                // Wind effect layer (separate from island — Canvas expands to fill)
                if currentScreen.showsWind {
                    WindLinesView(
                        windProgress: windProgress,
                        direction: 1.0,
                        windAreaTop: 0.08,
                        windAreaBottom: 0.42
                    )
                    .allowsHitTesting(false)
                }

                // Persistent island — always at bottom, never re-created
                islandLayer(screenHeight: geometry.size.height)

                // Step content overlay (narrative + bottom actions)
                stepOverlay(screenHeight: geometry.size.height)
                    .animation(.easeInOut(duration: 0.4), value: currentScreen)

                // Progress indicator
                progressIndicator
            }
        }
        .gesture(swipeBackGesture, including: currentScreen == .screenTimeData || currentScreen == .windSlider ? .subviews : .all)
    }

    // MARK: - Island Layer

    @ViewBuilder
    private func islandLayer(screenHeight: CGFloat) -> some View {
        // Always use OnboardingIslandView — pet visibility controlled by petOpacity.
        // This prevents the cross-dissolve flash when transitioning from screen 1 to 2.
        OnboardingIslandView(
            screenHeight: screenHeight,
            pet: Blob.shared,
            petOpacity: showBlob ? 1.0 : 0.0,
            windProgress: windProgress,
            eyesOverride: eyesOverride,
            speechBubbleConfig: speechBubbleConfig,
            speechBubbleVisible: speechBubbleVisible,
            onPetTap: onPetTap,
            showTapHint: showTapHint
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    // MARK: - Step Overlay

    @ViewBuilder
    private func stepOverlay(screenHeight: CGFloat) -> some View {
        switch currentScreen {
        case .island:
            OnboardingIslandStep(
                skipAnimation: visitedScreens.contains(.island),
                onContinue: advanceScreen
            )

        case .meetPet:
            OnboardingMeetPetStep(
                screenHeight: screenHeight,
                skipAnimation: visitedScreens.contains(.meetPet),
                onContinue: advanceScreen,
                showBlob: $showBlob,
                onPetTap: $onPetTap,
                speechBubbleConfig: $speechBubbleConfig,
                speechBubbleVisible: $speechBubbleVisible,
                showTapHint: $showTapHint
            )

        case .wind:
            OnboardingWindStep(
                skipAnimation: visitedScreens.contains(.wind),
                onContinue: advanceScreen,
                windProgress: $windProgress,
                eyesOverride: $eyesOverride
            )

        case .screenTimeData:
            OnboardingDataStep(
                skipAnimation: visitedScreens.contains(.screenTimeData),
                onContinue: advanceScreen
            )

        case .windSlider:
            OnboardingWindSliderStep(
                skipAnimation: visitedScreens.contains(.windSlider),
                onContinue: advanceScreen,
                windProgress: $windProgress,
                eyesOverride: $eyesOverride
            )

        default:
            nonStoryLayout
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        VStack {
            HStack {
                Button {
                    HapticType.impactLight.trigger()
                    goBack()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .opacity(currentScreen.previous != nil ? 1 : 0)
                .disabled(currentScreen.previous == nil)

                Spacer()

                StepIndicator(
                    currentStep: currentScreen.rawValue,
                    totalSteps: OnboardingScreen.totalCount
                )

                Spacer()

                Color.clear
                    .frame(width: 20, height: 20)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()
        }
    }

    // MARK: - Non-Story Layout (Screens 4+)

    /// Screens that have dedicated step views (not placeholders).
    private static let implementedScreens: Set<OnboardingScreen> = [
        .island, .meetPet, .wind, .screenTimeData, .windSlider,
    ]

    private var nonStoryLayout: some View {
        TabView(selection: $currentScreen) {
            ForEach(OnboardingScreen.allCases.filter { !Self.implementedScreens.contains($0) }) { screen in
                OnboardingPlaceholderStep(screen: screen)
                    .tag(screen)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(.easeInOut(duration: 0.3), value: currentScreen)
    }

    // MARK: - Gestures

    private var swipeBackGesture: some Gesture {
        DragGesture(minimumDistance: 30, coordinateSpace: .local)
            .onEnded { value in
                if value.translation.width > 50, abs(value.translation.height) < abs(value.translation.width) {
                    HapticType.impactLight.trigger()
                    goBack()
                }
            }
    }

    // MARK: - Navigation

    private func goBack() {
        guard let previous = currentScreen.previous else { return }
        visitedScreens.insert(currentScreen)

        // Reset shared state that the target screen doesn't expect
        switch previous {
        case .island:
            showBlob = false
            windProgress = 0
            eyesOverride = nil
            speechBubbleConfig = nil
            speechBubbleVisible = false
        case .meetPet:
            windProgress = 0
            eyesOverride = nil
        case .screenTimeData:
            windProgress = 0.15
            eyesOverride = nil
        default:
            break
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            currentScreen = previous
        }
    }

    private func advanceScreen() {
        if currentScreen.isLast {
            hasCompletedOnboarding = true
            return
        }
        guard let next = currentScreen.next else { return }
        visitedScreens.insert(currentScreen)
        withAnimation(.easeInOut(duration: 0.3)) {
            currentScreen = next
        }
    }
}

#if DEBUG
#Preview {
    OnboardingView()
}
#endif
