import SwiftUI

struct OnboardingMeetPetStep: View {
    let screenHeight: CGFloat
    let skipAnimation: Bool
    var onContinue: () -> Void

    @Binding var showBlob: Bool
    @Binding var onPetTap: (() -> Void)?
    @Binding var speechBubbleConfig: SpeechBubbleConfig?
    @Binding var speechBubbleVisible: Bool
    @Binding var showTapHint: Bool

    @State private var showSecondLine = false
    @State private var textCompleted = false
    @State private var hasBeenTapped = false
    @State private var speechBubbleTask: Task<Void, Never>?
    @State private var narrativeBeat = 0

    var body: some View {
        Color.clear
            .overlay(alignment: .top) {
                narrative
                    .padding(.horizontal, 32)
                    .padding(.top, 60)
            }
            .overlay(alignment: .bottom) {
                if hasBeenTapped {
                    continueButton
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                }
            }
            .overlay {
                // Tap-to-skip overlay — disappears after text completes so pet tap works
                if !textCompleted && !skipAnimation {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticType.impactLight.trigger()
                            if !showBlob {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showBlob = true
                                }
                            }
                            narrativeBeat += 1
                        }
                }
            }
            .onAppear {
                // Register pet tap handler
                onPetTap = handleBlobTap

                if skipAnimation {
                    showBlob = true
                    showSecondLine = true
                    textCompleted = true
                    hasBeenTapped = true
                } else {
                    Task {
                        try? await Task.sleep(for: .seconds(0.5))
                        withAnimation(.easeInOut(duration: 0.6)) {
                            showBlob = true
                        }
                    }
                }
            }
            .onDisappear {
                onPetTap = nil
                showTapHint = false
                speechBubbleTask?.cancel()
                speechBubbleTask = nil
                // Hide speech bubble when leaving this step
                speechBubbleVisible = false
                speechBubbleConfig = nil
            }
    }

    // MARK: - Narrative

    private var narrative: some View {
        VStack(spacing: 12) {
            if skipAnimation {
                Text("Meet Uuumi.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
                Text("A tiny creature looking for somewhere to grow.")
            } else {
                TypewriterText(
                    text: "Meet Uuumi.",
                    skipRequested: narrativeBeat >= 1,
                    onCompleted: {
                        Task {
                            if narrativeBeat < 1 {
                                try? await Task.sleep(for: .seconds(0.5))
                            }
                            withAnimation { showSecondLine = true }
                        }
                    }
                )
                .font(AppFont.quicksand(.title2, weight: .semiBold))

                TypewriterText(
                    text: "A tiny creature looking for somewhere to grow.",
                    active: showSecondLine,
                    skipRequested: narrativeBeat >= 2,
                    onCompleted: {
                        textCompleted = true
                        withAnimation(.easeOut(duration: 0.4)) {
                            showTapHint = true
                        }
                    }
                )
                .opacity(showSecondLine ? 1 : 0)
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

    private func handleBlobTap() {
        guard !hasBeenTapped else { return }
        hasBeenTapped = true
        withAnimation(.easeOut(duration: 0.3)) {
            showTapHint = false
        }

        // Show waving hand speech bubble
        speechBubbleConfig = SpeechBubbleConfig(
            position: .right,
            emojis: ["👋"],
            windLevel: .none,
            displayDuration: 2.5
        )
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            speechBubbleVisible = true
        }

        // Hide after display duration
        speechBubbleTask = Task {
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                speechBubbleVisible = false
            }
            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled else { return }
            speechBubbleConfig = nil
        }
    }
}

#if DEBUG
#Preview {
    GeometryReader { geometry in
        ZStack {
            OnboardingBackgroundView()
            OnboardingIslandView(
                screenHeight: geometry.size.height,
                pet: Blob.shared
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(.container, edges: .bottom)
            OnboardingMeetPetStep(
                screenHeight: geometry.size.height,
                skipAnimation: false,
                onContinue: {},
                showBlob: .constant(true),
                onPetTap: .constant(nil),
                speechBubbleConfig: .constant(nil),
                speechBubbleVisible: .constant(false),
                showTapHint: .constant(false)
            )
        }
    }
}
#endif
