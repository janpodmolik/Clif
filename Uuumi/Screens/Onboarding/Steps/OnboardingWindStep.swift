import SwiftUI

struct OnboardingWindStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void

    @Binding var windProgress: CGFloat
    @Binding var eyesOverride: String?

    @Environment(\.onboardingFontScale) private var fontScale

    @State private var showSecondLine = false
    @State private var showThirdLine = false
    @State private var textCompleted = false

    @ObservedObject private var screenTimeManager = ScreenTimeManager.shared
    @State private var showPermissionCTA = false
    @State private var showPermissionDenied = false
    @State private var isRequestingPermission = false
    @State private var didAdvance = false
    @State private var narrativeBeat = 0

    // MARK: - Narrative Text
    private let narrativeLine1 = "The wind comes from your screen time."
    private let narrativeLine2 = "The more you scroll, the stronger it gets."
    private let narrativeLine3 = "Let's see what Uuumi is up against."

    var body: some View {
        Color.clear
            .overlay(alignment: .top) {
                narrative
                    .padding(.horizontal, 32)
                    .padding(.top, 60)
            }
            .overlay(alignment: .bottom) {
                bottomArea
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
            .overlay {
                if !textCompleted && !skipAnimation {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticType.impactLight.trigger()
                            narrativeBeat += 1
                        }
                }
            }
            .onAppear {
                if skipAnimation {
                    windProgress = OnboardingScreen.wind.initialWindProgress ?? 0.15
                    eyesOverride = "neutral"
                    textCompleted = true
                    showSecondLine = true
                    showThirdLine = true
                    showPermissionCTA = true
                }
            }
            // eyesOverride intentionally kept — next step expects neutral eyes during transition
    }

    // MARK: - Narrative

    private var narrative: some View {
        VStack(spacing: 12) {
            Group {
                if skipAnimation {
                    Text(narrativeLine1)
                } else {
                    let skipped = narrativeBeat >= 1
                    TypewriterText(
                        text: narrativeLine1,
                        skipRequested: skipped,
                        onCompleted: {
                            withAnimation(.easeInOut(duration: skipped ? 0.5 : 1.0)) {
                                windProgress = 0.08
                            }
                            Task {
                                if !skipped {
                                    try? await Task.sleep(for: .seconds(0.5))
                                }
                                withAnimation { showSecondLine = true }
                            }
                        }
                    )
                }
            }

            Group {
                if skipAnimation {
                    Text(narrativeLine2)
                } else {
                    let skipped = narrativeBeat >= 1
                    TypewriterText(
                        text: narrativeLine2,
                        active: showSecondLine,
                        skipRequested: narrativeBeat >= 2,
                        onCompleted: {
                            withAnimation(.easeInOut(duration: skipped ? 0.5 : 1.0)) {
                                windProgress = OnboardingScreen.wind.initialWindProgress ?? 0.15
                            }
                            Task {
                                if narrativeBeat < 2 {
                                    try? await Task.sleep(for: .seconds(0.8))
                                }
                                eyesOverride = "neutral"
                                withAnimation(.easeIn(duration: skipped ? 0.3 : 0.6)) {
                                    showThirdLine = true
                                }
                                textCompleted = true
                                withAnimation(.easeOut(duration: skipped ? 0.3 : 0.4)) {
                                    showPermissionCTA = true
                                }
                            }
                        }
                    )
                    .opacity(showSecondLine ? 1 : 0)
                }
            }

            Group {
                if skipAnimation {
                    Text(narrativeLine3)
                } else {
                    Text(narrativeLine3)
                        .opacity(showThirdLine ? 1 : 0)
                }
            }
            .font(AppFont.quicksandOnboarding(.title2, weight: .semiBold, scale: fontScale))
            .padding(.top, 12)
        }
        .font(AppFont.quicksandOnboarding(.title3, weight: .medium, scale: fontScale))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Bottom Area

    @ViewBuilder
    private var bottomArea: some View {
        if showPermissionCTA && !screenTimeManager.isAuthorized {
            permissionCTAView
                .transition(.opacity)
        } else if showPermissionCTA && screenTimeManager.isAuthorized {
            continueButton
                .transition(.opacity)
        }
    }

    private var continueButton: some View {
        Button {
            HapticType.impactLight.trigger()
            onContinue()
        } label: {
            Text("Continue")
        }
        .buttonStyle(.primary)
        .padding(.horizontal, 24)
    }

    // MARK: - Permission CTA

    private var permissionCTAView: some View {
        VStack(spacing: 16) {
            if showPermissionDenied {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)

                    Text("Screen Time access is required")
                        .font(AppFont.quicksandOnboarding(.headline, weight: .semiBold, scale: fontScale))
                        .foregroundStyle(.primary)

                    Text("Without it, there's no wind, no protection, no evolution.")
                        .font(AppFont.quicksandOnboarding(.subheadline, weight: .medium, scale: fontScale))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }

            Text("Your data stays on your device. Always.")
                .font(AppFont.quicksandOnboarding(.footnote, weight: .medium, scale: fontScale))
                .foregroundStyle(.primary.opacity(0.7))

            Button {
                HapticType.impactMedium.trigger()
                requestPermission()
            } label: {
                if isRequestingPermission {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(showPermissionDenied ? "Try again" : "Show my screen time")
                }
            }
            .buttonStyle(.primary)
            .disabled(isRequestingPermission)
        }
    }

    // MARK: - Actions

    private func requestPermission() {
        isRequestingPermission = true
        showPermissionDenied = false
        Task {
            await screenTimeManager.requestAuthorization()
            isRequestingPermission = false
            if screenTimeManager.isAuthorized, !didAdvance {
                didAdvance = true
                try? await Task.sleep(for: .seconds(0.5))
                onContinue()
            } else if !screenTimeManager.isAuthorized {
                withAnimation {
                    showPermissionDenied = true
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    OnboardingStepPreview(windProgress: 0.15, showWind: true) { _, windProgress, eyesOverride, _ in
        OnboardingWindStep(
            skipAnimation: false,
            onContinue: {},
            windProgress: windProgress,
            eyesOverride: eyesOverride
        )
    }
}
#endif
