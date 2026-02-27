import SwiftUI

struct OnboardingEvolutionStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void
    @Binding var eyesOverride: String?

    @State private var narrativeBeat = 0
    @State private var showSecondLine = false
    @State private var textCompleted = false
    @State private var showButton = false

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
    }

    // MARK: - Narrative

    private var narrative: some View {
        VStack(spacing: 12) {
            if skipAnimation {
                Text("Protect your Uuumi each day, and it evolves.")
                Text("A new form. A new beginning.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
                    .padding(.top, 8)
            } else {
                let skipped = narrativeBeat >= 1

                TypewriterText(
                    text: "Protect your Uuumi each day, and it evolves.",
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
                    text: "A new form. A new beginning.",
                    active: showSecondLine,
                    skipRequested: narrativeBeat >= 2,
                    onCompleted: {
                        textCompleted = true
                        Task {
                            try? await Task.sleep(for: .seconds(0.3))
                            withAnimation { showButton = true }
                        }
                    }
                )
                .font(AppFont.quicksand(.title2, weight: .semiBold))
                .opacity(showSecondLine ? 1 : 0)
                .padding(.top, 8)
            }
        }
        .font(AppFont.quicksand(.title3, weight: .medium))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Continue

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

    private func handleAppear() {
        eyesOverride = "happy"

        if skipAnimation {
            showSecondLine = true
            textCompleted = true
            showButton = true
        }
    }
}

#if DEBUG
#Preview {
    OnboardingStepPreview(showBlob: true, showWind: false) { _, _, eyesOverride in
        OnboardingEvolutionStep(
            skipAnimation: false,
            onContinue: {},
            eyesOverride: eyesOverride
        )
    }
}
#endif
