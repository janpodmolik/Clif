import SwiftUI

struct OnboardingWindStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void

    @Binding var windProgress: CGFloat
    @Binding var eyesOverride: String?

    @State private var showSecondLine = false
    @State private var showThirdLine = false
    @State private var textCompleted = false

    @ObservedObject private var screenTimeManager = ScreenTimeManager.shared
    @State private var showPermissionCTA = false
    @State private var showPermissionDenied = false
    @State private var isRequestingPermission = false
    @State private var didAdvance = false
    @State private var narrativeBeat = 0

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
            .onDisappear {
                eyesOverride = nil
            }
    }

    // MARK: - Narrative

    private var narrative: some View {
        VStack(spacing: 12) {
            if skipAnimation {
                Text("The wind comes from your screen time.")
                Text("The more you scroll, the stronger it gets.")
                Text("Let's see what Uuumi is up against.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
                    .padding(.top, 12)
            } else {
                let skipped = narrativeBeat >= 1

                TypewriterText(
                    text: "The wind comes from your screen time.",
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

                TypewriterText(
                    text: "The more you scroll, the stronger it gets.",
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

                Text("Let's see what Uuumi is up against.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
                    .padding(.top, 12)
                    .opacity(showThirdLine ? 1 : 0)
            }
        }
        .font(AppFont.quicksand(.title3, weight: .medium))
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
                        .font(AppFont.quicksand(.headline, weight: .semiBold))
                        .foregroundStyle(.primary)

                    Text("Without it, there's no wind, no protection, no evolution.")
                        .font(AppFont.quicksand(.subheadline, weight: .medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }

            Text("Your data stays on your device. Always.")
                .font(AppFont.quicksand(.caption, weight: .medium))
                .foregroundStyle(.secondary)

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
    OnboardingStepPreview(windProgress: 0.15, showWind: true) { _, windProgress, eyesOverride in
        OnboardingWindStep(
            skipAnimation: false,
            onContinue: {},
            windProgress: windProgress,
            eyesOverride: eyesOverride
        )
    }
}
#endif
