import SwiftUI

struct OnboardingLoginStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void
    @Binding var eyesOverride: String?

    @Environment(AuthManager.self) private var authManager
    @Environment(PetManager.self) private var petManager
    @Environment(\.onboardingFontScale) private var fontScale

    // MARK: - Narrative State

    @State private var narrativeBeat = 0
    @State private var showSubtitle = false
    @State private var showPrivacy = false
    @State private var showProviders = false
    @State private var showSkip = false
    @State private var textCompleted = false

    private var petName: String {
        petManager.currentPet?.name ?? "Your Uuumi"
    }

    var body: some View {
        VStack(spacing: 0) {
            narrative
                .padding(.horizontal, 32)
                .padding(.top, 60)

            Spacer()

            if showProviders {
                bottomArea
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.opacity)
            }
        }
        .overlay {
            tapToSkipOverlay
        }
        .animation(.easeOut(duration: 0.3), value: showProviders)
        .onAppear { handleAppear() }
    }

    // MARK: - Narrative

    private var narrative: some View {
        VStack(spacing: 12) {
            if skipAnimation {
                Text("Keep \(petName) safe!")
                subtitle
                privacyNote
            } else {
                let skipped = narrativeBeat >= 1

                TypewriterText(
                    text: "Keep \(petName) safe!",
                    skipRequested: skipped,
                    onCompleted: {
                        Task {
                            if !skipped {
                                try? await Task.sleep(for: .seconds(0.3))
                            }
                            withAnimation { showSubtitle = true }
                        }
                    }
                )

                if showSubtitle {
                    TypewriterText(
                        text: "Sign in to save your progress, coins, and streaks. Restore everything if you switch devices or reinstall.",
                        active: showSubtitle,
                        skipRequested: narrativeBeat >= 2,
                        onCompleted: {
                            Task {
                                if narrativeBeat < 2 {
                                    try? await Task.sleep(for: .seconds(0.2))
                                }
                                withAnimation { showPrivacy = true }
                                try? await Task.sleep(for: .seconds(0.3))
                                textCompleted = true
                                revealProviders()
                            }
                        }
                    )
                    .font(AppFont.quicksandOnboarding(.callout, weight: .semiBold, scale: fontScale))
                    .foregroundStyle(.secondary)
                }

                if showPrivacy {
                    privacyNote
                        .transition(.opacity)
                }
            }
        }
        .font(AppFont.quicksandOnboarding(.title2, weight: .semiBold, scale: fontScale))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
    }

    private var subtitle: some View {
        Text("Sign in to save your progress, coins, and streaks. Restore everything if you switch devices or reinstall.")
            .font(AppFont.quicksandOnboarding(.callout, weight: .semiBold, scale: fontScale))
            .foregroundStyle(.secondary)
    }

    private var privacyNote: some View {
        Text("We only store your progress, nothing else.")
            .font(AppFont.quicksandOnboarding(.caption, weight: .medium, scale: fontScale))
            .foregroundStyle(.secondary)
            .padding(.top, 4)
    }

    // MARK: - Bottom Area

    private var bottomArea: some View {
        VStack(spacing: 12) {
            AuthProviderButtons {
                onContinue()
            }

            if showSkip {
                Button {
                    HapticType.impactLight.trigger()
                    onContinue()
                } label: {
                    Text("Maybe later")
                        .font(.subheadline)
                        .foregroundStyle(.primary.opacity(0.6))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
                .transition(.opacity)
            }
        }
    }

    // MARK: - Tap to Skip

    @ViewBuilder
    private var tapToSkipOverlay: some View {
        if !skipAnimation && !textCompleted {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticType.impactLight.trigger()
                    narrativeBeat += 1
                }
        }
    }

    // MARK: - Actions

    private func revealProviders() {
        Task {
            try? await Task.sleep(for: .seconds(0.2))
            withAnimation { showProviders = true }
            try? await Task.sleep(for: .seconds(0.8))
            withAnimation { showSkip = true }
        }
    }

    // MARK: - Lifecycle

    private func handleAppear() {
        eyesOverride = "happy"

        if skipAnimation {
            showSubtitle = true
            showPrivacy = true
            textCompleted = true
            showProviders = true
            showSkip = true
        }
    }
}

#if DEBUG
#Preview {
    OnboardingStepPreview(showBlob: true, showWind: false) { _, _, eyesOverride, _ in
        OnboardingLoginStep(
            skipAnimation: false,
            onContinue: {},
            eyesOverride: eyesOverride
        )
        .environment(AuthManager.mock())
        .environment(PetManager())
        .environment(AnalyticsManager())
    }
}
#endif
