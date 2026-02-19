import SwiftUI

struct OnboardingView: View {
    @AppStorage(DefaultsKeys.hasCompletedOnboarding)
    private var hasCompletedOnboarding = false

    @Environment(\.colorScheme) private var colorScheme
    @State private var currentScreen: OnboardingScreen = .island

    // Navigation state
    @State private var visitedScreens: Set<OnboardingScreen> = []

    // Island state
    @State private var showBlob = false
    @State private var showTapHint = false
    @State private var hasBeenTapped = false
    @State private var isPulsing = false
    @State private var reactionAnimator = PetReactionAnimator()

    private var isStoryScreen: Bool {
        currentScreen.act == .story
    }

    var body: some View {
        ZStack {
            onboardingBackground

            if isStoryScreen {
                storyLayout
            } else {
                nonStoryLayout
            }

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

                    // Balance the back button width
                    Color.clear
                        .frame(width: 20, height: 20)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                Spacer()

                continueButton
                    .padding(.horizontal, 24)
            }
        }
        .gesture(
            DragGesture(minimumDistance: 30, coordinateSpace: .local)
                .onEnded { value in
                    // Swipe right → go back
                    if value.translation.width > 50, abs(value.translation.height) < abs(value.translation.width) {
                        HapticType.impactLight.trigger()
                        goBack()
                    }
                }
        )
    }

    // MARK: - Story Layout (Screens 1-3)

    private var storyLayout: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                OnboardingNarrativeView(
                    screen: currentScreen,
                    skipAnimation: visitedScreens.contains(currentScreen),
                    onTextCompleted: handleNarrativeCompleted
                )
                .animation(.easeInOut(duration: 0.4), value: currentScreen)

                Spacer()

                islandScene(screenHeight: geometry.size.height)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    // MARK: - Island Scene

    @ViewBuilder
    private func islandScene(screenHeight: CGFloat) -> some View {
        ZStack {
            // IslandView contains its own IslandBase, so only show standalone
            // base when blob is hidden. Both use identical positioning.
            if showBlob {
                IslandView(
                    screenHeight: screenHeight,
                    content: .pet(Blob.shared, windProgress: 0, windDirection: 1.0, windRhythm: nil),
                    reactionAnimator: reactionAnimator,
                    onPetTap: handleBlobTap
                )
            } else {
                IslandBase(screenHeight: screenHeight)
            }

            if showTapHint && !hasBeenTapped {
                tapHintOverlay
                    // Position just above the blob
                    .offset(y: -(screenHeight * 0.18))
                    .transition(.opacity.animation(.easeOut(duration: 0.4)))
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tap Hint

    private var tapHintOverlay: some View {
        VStack(spacing: 4) {
            Image(systemName: "hand.tap.fill")
                .font(.title3)
            Text("Tap")
                .font(AppFont.quicksand(.caption, weight: .medium))
        }
        .foregroundStyle(.secondary)
        .scaleEffect(isPulsing ? 1.15 : 1.0)
        .opacity(isPulsing ? 1.0 : 0.6)
        .animation(
            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
            value: isPulsing
        )
        .onAppear { isPulsing = true }
        .allowsHitTesting(false)
    }

    // MARK: - Non-Story Layout (Screens 4+)

    private var nonStoryLayout: some View {
        TabView(selection: $currentScreen) {
            ForEach(OnboardingScreen.allCases.filter { $0.act != .story }) { screen in
                OnboardingPlaceholderStep(screen: screen)
                    .tag(screen)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea(.container, edges: .bottom)
        .animation(.easeInOut(duration: 0.3), value: currentScreen)
    }

    // MARK: - Background

    @ViewBuilder
    private var onboardingBackground: some View {
        switch colorScheme {
        case .dark:
            NightBackgroundView()
        default:
            DayBackgroundView()
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            HapticType.impactLight.trigger()
            advanceScreen()
        } label: {
            Text(currentScreen.isLast ? "Start" : "Continue")
        }
        .buttonStyle(.primary)
    }

    // MARK: - Actions

    private func goBack() {
        guard let previous = currentScreen.previous else { return }

        visitedScreens.insert(currentScreen)

        // Reverse state transitions (no animation — instant)
        switch currentScreen {
        case .meetPet:
            showBlob = false
            showTapHint = false
            hasBeenTapped = false

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

        switch next {
        case .meetPet:
            currentScreen = next
            if !visitedScreens.contains(.meetPet) {
                Task {
                    try? await Task.sleep(for: .seconds(0.5))
                    withAnimation(.easeInOut(duration: 0.6)) {
                        showBlob = true
                    }
                }
            } else {
                showBlob = true
            }

        default:
            currentScreen = next
        }
    }

    private func handleNarrativeCompleted() {
        guard currentScreen == .meetPet else { return }

        withAnimation(.easeOut(duration: 0.4)) {
            showTapHint = true
        }
    }

    private func handleBlobTap() {
        guard !hasBeenTapped else { return }
        hasBeenTapped = true
        withAnimation(.easeOut(duration: 0.3)) {
            showTapHint = false
        }
    }
}

#if DEBUG
#Preview {
    OnboardingView()
}
#endif
