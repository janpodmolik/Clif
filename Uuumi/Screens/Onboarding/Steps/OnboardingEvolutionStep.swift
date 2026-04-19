import SwiftUI

struct OnboardingEvolutionStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void
    @Binding var eyesOverride: String?
    @Binding var showThoughtBubble: Bool

    @Environment(\.onboardingFontScale) private var fontScale

    @State private var narrativeBeat = 0
    @State private var showSecondLine = false
    @State private var textCompleted = false
    @State private var showButton = false

    // MARK: - Narrative Text
    private let narrativeLine1 = "Protect your Uuumi each day, and it evolves."
    private let narrativeLine2 = "A new form. A new beginning."

    var body: some View {
        VStack(spacing: 0) {
            narrative
                .padding(.horizontal, 32)
                .padding(.top, 60)

            Spacer()

            if showButton {
                continueButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.opacity)
            }
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
        .animation(.easeOut(duration: 0.3), value: showButton)
        .onAppear { handleAppear() }
        .onDisappear { handleDisappear() }
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
                    TypewriterText(
                        text: narrativeLine2,
                        active: showSecondLine,
                        skipRequested: narrativeBeat >= 2,
                        onCompleted: {
                            textCompleted = true
                            showThoughtBubble = true
                            Task {
                                try? await Task.sleep(for: .seconds(0.3))
                                withAnimation { showButton = true }
                            }
                        }
                    )
                    .opacity(showSecondLine ? 1 : 0)
                }
            }
            .font(AppFont.quicksandOnboarding(.title2, weight: .semiBold, scale: fontScale))
            .padding(.top, 8)
        }
        .font(AppFont.quicksandOnboarding(.title3, weight: .medium, scale: fontScale))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Continue

    private var continueButton: some View {
        Button {
            HapticType.impactLight.trigger()
            showThoughtBubble = false
            onContinue()
        } label: {
            Text("Continue")
        }
        .buttonStyle(.primary)
    }

    // MARK: - Actions

    private func handleAppear() {
        eyesOverride = "happy"

        if skipAnimation {
            showSecondLine = true
            textCompleted = true
            showButton = true
            showThoughtBubble = true
        }
    }

    private func handleDisappear() {
        showThoughtBubble = false
    }
}

#if DEBUG
#Preview {
    OnboardingStepPreview(showBlob: true, showWind: false) { _, _, eyesOverride, showThoughtBubble in
        OnboardingEvolutionStep(
            skipAnimation: false,
            onContinue: {},
            eyesOverride: eyesOverride,
            showThoughtBubble: showThoughtBubble
        )
    }
}
#endif
