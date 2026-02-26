import SwiftUI

struct OnboardingLockStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void

    @Binding var windProgress: CGFloat
    @Binding var eyesOverride: String?

    // MARK: - Constants

    /// Wind progress this screen starts with (from `OnboardingScreen.initialWindProgress`).
    private let entryWind = OnboardingScreen.lockDemo.initialWindProgress ?? 0.7
    /// Wind progress handed to the next screen on disappear.
    private let exitWind: CGFloat = 0.55
    /// Lock button size matching the home-screen lock (55×55), scaled up when unlocked.
    private let buttonSize: CGFloat = 55
    private let unlockedScale: CGFloat = 80 / 55
    /// Lock animation: total duration and step count for the wind drop.
    private let windDropDuration: Double = 2.5
    private let windDropSteps = 20
    /// How much wind must drop before the lock slides to the trailing edge.
    private let settleDropThreshold: CGFloat = 0.15

    // MARK: - State

    // Phase 1 — pre-lock narrative
    @State private var narrativeBeat = 0
    @State private var showSecondLine = false
    @State private var textCompleted = false

    // Lock state
    @State private var isLocked = false
    @State private var isGlowing = false
    @State private var isPulsing = false
    @State private var lockSettled = false

    // Phase 2 — post-lock narrative
    @State private var showPostLock = false
    @State private var postLockBeat = 0
    @State private var showPostLockLine2 = false
    @State private var showPostLockLine3 = false
    @State private var postLockTextCompleted = false

    private var windLevel: WindLevel {
        WindLevel.from(progress: windProgress)
    }

    private var windLabel: String {
        switch windLevel {
        case .none: "A calm day."
        case .low: "A little breezy..."
        case .medium: "Uuumi is struggling."
        case .high: "Too much. Uuumi can't hold on."
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let lockY = geometry.size.height * 0.7 - buttonSize / 2
            let unlockedCenter = CGPoint(
                x: geometry.size.width / 2,
                y: lockY
            )
            let settledCenter = CGPoint(
                x: geometry.size.width - 20 - buttonSize / 2,
                y: lockY
            )
            let targetCenter = lockSettled ? settledCenter : unlockedCenter

            VStack(spacing: 0) {
                narrativeArea
                    .padding(.horizontal, 32)
                    .padding(.top, 60)

                Spacer()

                progressBarArea
                    .padding(.horizontal, 24)

                Spacer()
                    .frame(height: 16)

                continueButton
                    .padding(.horizontal, 24)
                    .opacity(postLockTextCompleted && lockSettled ? 1 : 0)
                    .animation(.easeOut(duration: 0.3), value: postLockTextCompleted)
                    .animation(.easeOut(duration: 0.3), value: lockSettled)
            }
            .overlay {
                lockButtonView
                    .scaleEffect(lockSettled ? 1.0 : unlockedScale)
                    .shadow(
                        color: .cyan.opacity(isGlowing ? 0.7 : 0),
                        radius: isGlowing ? 20 : 0
                    )
                    .position(targetCenter)
                    .opacity(textCompleted || skipAnimation ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.4), value: textCompleted)
                    .animation(.easeInOut(duration: 0.6), value: lockSettled)
            }
            .overlay {
                tapToSkipOverlay
            }
        }
        .onAppear { handleAppear() }
        .onDisappear { handleDisappear() }
        .onChange(of: windProgress) { _, newValue in
            eyesOverride = WindLevel.from(progress: newValue).eyes
        }
    }

    // MARK: - Narrative Area

    @ViewBuilder
    private var narrativeArea: some View {
        if showPostLock {
            postLockNarrative
                .transition(.opacity)
        } else {
            preLockNarrative
                .transition(.opacity)
        }
    }

    private var preLockNarrative: some View {
        VStack(spacing: 12) {
            if skipAnimation {
                Text("But you have the power to stop it.")
                Text("Tap the lock.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
                    .padding(.top, 12)
            } else {
                let skipped = narrativeBeat >= 1

                TypewriterText(
                    text: "But you have the power to stop it.",
                    skipRequested: skipped,
                    onCompleted: {
                        Task {
                            if !skipped {
                                try? await Task.sleep(for: .seconds(0.5))
                            }
                            withAnimation { showSecondLine = true }
                        }
                    }
                )

                TypewriterText(
                    text: "Tap the lock.",
                    active: showSecondLine,
                    skipRequested: narrativeBeat >= 2,
                    onCompleted: {
                        textCompleted = true
                    }
                )
                .font(AppFont.quicksand(.title2, weight: .semiBold))
                .opacity(showSecondLine ? 1 : 0)
                .padding(.top, 12)
            }
        }
        .font(AppFont.quicksand(.title3, weight: .medium))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
    }

    private var postLockNarrative: some View {
        VStack(spacing: 12) {
            if skipAnimation {
                Text("The wind stops. Uuumi is safe.")
                Text("This isn't about willpower. It's about protecting something you care about.")
                Text("When the wind rises, you can lock in and calm it.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
                    .padding(.top, 12)
            } else {
                let skipped = postLockBeat >= 1

                TypewriterText(
                    text: "The wind stops. Uuumi is safe.",
                    skipRequested: skipped,
                    onCompleted: {
                        Task {
                            if !skipped {
                                try? await Task.sleep(for: .seconds(0.5))
                            }
                            withAnimation { showPostLockLine2 = true }
                        }
                    }
                )

                TypewriterText(
                    text: "This isn't about willpower. It's about protecting something you care about.",
                    active: showPostLockLine2,
                    skipRequested: postLockBeat >= 2,
                    onCompleted: {
                        Task {
                            if postLockBeat < 2 {
                                try? await Task.sleep(for: .seconds(0.5))
                            }
                            withAnimation { showPostLockLine3 = true }
                        }
                    }
                )
                .opacity(showPostLockLine2 ? 1 : 0)

                TypewriterText(
                    text: "When the wind rises, you can lock in and calm it.",
                    active: showPostLockLine3,
                    skipRequested: postLockBeat >= 3,
                    onCompleted: {
                        postLockTextCompleted = true
                    }
                )
                .font(AppFont.quicksand(.title2, weight: .semiBold))
                .opacity(showPostLockLine3 ? 1 : 0)
                .padding(.top, 12)
            }
        }
        .font(AppFont.quicksand(.title3, weight: .medium))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Progress Bar Area

    private var progressBarArea: some View {
        VStack(spacing: 8) {
            Text(windLabel)
                .font(AppFont.quicksand(.body, weight: .medium))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: windLevel)

            WindProgressBar(progress: windProgress, isPulsing: isPulsing)
        }
    }

    // MARK: - Lock Button

    @ViewBuilder
    private var lockButtonView: some View {
        let content = Button {
            handleLockTap()
        } label: {
            Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                .font(.title2.weight(.semibold))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: buttonSize, height: buttonSize)
        }
        .contentShape(Circle().inset(by: -10))
        .buttonStyle(.pressableButton)
        .disabled(isLocked || !textCompleted)
        .allowsHitTesting(!isLocked && textCompleted)
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular.interactive(), in: .circle)
        } else {
            content
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    // MARK: - Tap-to-Skip Overlay

    @ViewBuilder
    private var tapToSkipOverlay: some View {
        if !skipAnimation {
            if !textCompleted && !isLocked {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticType.impactLight.trigger()
                        narrativeBeat += 1
                    }
            } else if showPostLock && !postLockTextCompleted {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        HapticType.impactLight.trigger()
                        postLockBeat += 1
                    }
            }
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button {
            HapticType.impactLight.trigger()
            onContinue()
        } label: {
            Text("Continue")
        }
        .buttonStyle(.primary)
    }

    // MARK: - Actions

    private func handleLockTap() {
        HapticType.notificationSuccess.trigger()

        // Step 1: Lock icon animation + glow (stays in place)
        isLocked = true

        withAnimation(.easeOut(duration: 0.3)) {
            isGlowing = true
        }

        Task {
            // Fade out glow
            try? await Task.sleep(for: .seconds(0.4))
            withAnimation(.easeIn(duration: 0.5)) {
                isGlowing = false
            }

            // Step 2: Bar turns blue (isPulsing → cyan) and wind gradually decreases step by step
            try? await Task.sleep(for: .seconds(0.3))
            isPulsing = true

            let startProgress = windProgress
            let stepDuration = windDropDuration / Double(windDropSteps)

            var hasSettled = false

            for step in 1...windDropSteps {
                try? await Task.sleep(for: .seconds(stepDuration))
                let fraction = CGFloat(step) / CGFloat(windDropSteps)
                // Ease-out curve: faster at start, slower at end
                let easedFraction = 1 - pow(1 - fraction, 2)
                withAnimation(.linear(duration: stepDuration)) {
                    windProgress = startProgress * (1 - easedFraction)
                }

                // Step 3: After wind drops enough, move lock to trailing + show narrative
                if !hasSettled && (startProgress - windProgress) >= settleDropThreshold {
                    hasSettled = true
                    withAnimation(.easeInOut(duration: 0.6)) {
                        lockSettled = true
                    }
                    Task {
                        try? await Task.sleep(for: .seconds(0.4))
                        withAnimation(.easeOut(duration: 0.4)) {
                            showPostLock = true
                        }
                    }
                }
            }

            // Ensure we land exactly at 0
            withAnimation(.linear(duration: stepDuration)) {
                windProgress = 0
            }
        }
    }

    private func handleAppear() {
        if skipAnimation {
            textCompleted = true
            showSecondLine = true
            isLocked = true
            lockSettled = true
            isPulsing = false
            showPostLock = true
            showPostLockLine2 = true
            showPostLockLine3 = true
            postLockTextCompleted = true
            windProgress = 0
            eyesOverride = WindLevel.from(progress: 0).eyes
        } else {
            if windProgress < entryWind {
                windProgress = entryWind
                eyesOverride = WindLevel.from(progress: entryWind).eyes
            }
        }
    }

    private func handleDisappear() {
        windProgress = exitWind
        eyesOverride = WindLevel.from(progress: exitWind).eyes
    }
}

#if DEBUG
#Preview {
    OnboardingStepPreview(windProgress: 0.6, showWind: true) { _, windProgress, eyesOverride in
        OnboardingLockStep(
            skipAnimation: false,
            onContinue: {},
            windProgress: windProgress,
            eyesOverride: eyesOverride
        )
    }
}
#endif
