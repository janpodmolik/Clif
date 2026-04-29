import StoreKit
import SwiftUI

struct OnboardingReviewStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void
    @Binding var eyesOverride: String?
    @Binding var speechBubbleConfig: SpeechBubbleConfig?
    @Binding var speechBubbleVisible: Bool
    @Binding var reactionTrigger: UUID?

    @Environment(PetManager.self) private var petManager
    @Environment(AnalyticsManager.self) private var analytics
    @Environment(\.requestReview) private var requestReview
    @Environment(\.onboardingFontScale) private var fontScale
    // MARK: - Narrative State

    @State private var narrativeBeat = 0
    @State private var showSecondLine = false
    @State private var textCompleted = false

    // MARK: - Narrative Text
    private let narrativeLine2 = "If you believe in what we're building, a review would mean the world to us."

    // MARK: - Review State

    @State private var reviewRequested = false
    @State private var showButtons = false

    private var petName: String {
        petManager.currentPet?.name ?? "Your Uuumi"
    }

    var body: some View {
        VStack(spacing: 0) {
            narrative
                .padding(.horizontal, 32)
                .padding(.top, 60)

            Spacer()

            if showButtons {
                bottomArea
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.opacity)
            }
        }
        .overlay {
            tapToSkipOverlay
        }
        .animation(.easeOut(duration: 0.3), value: showButtons)
        .onAppear { handleAppear() }
        .onDisappear {
            speechBubbleVisible = false
            speechBubbleConfig = nil
        }
    }

    // MARK: - Narrative

    private var narrative: some View {
        VStack(spacing: 12) {
            Group {
                if skipAnimation {
                    Text("\(petName) is ready.")
                } else {
                    let skipped = narrativeBeat >= 1
                    TypewriterText(
                        text: "\(petName) is ready.",
                        skipRequested: skipped,
                        onCompleted: {
                            Task {
                                if !skipped {
                                    try? await Task.sleep(for: .seconds(0.3))
                                }
                                showHeartBubble()
                                reactionTrigger = UUID()
                                if !skipped {
                                    try? await Task.sleep(for: .seconds(0.5))
                                }
                                withAnimation { showSecondLine = true }
                            }
                        }
                    )
                }
            }
            .font(AppFont.quicksandOnboarding(.title2, weight: .semiBold, scale: fontScale))

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
                            revealButtons()
                        }
                    )
                    .opacity(showSecondLine ? 1 : 0)
                }
            }
            .font(AppFont.quicksandOnboarding(.callout, weight: .semiBold, scale: fontScale))
            .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Bottom Area

    private var bottomArea: some View {
        Button {
            HapticType.impactLight.trigger()
            onContinue()
        } label: {
            Text("Continue")
        }
        .buttonStyle(.primary)
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

    private func showHeartBubble() {
        speechBubbleConfig = SpeechBubbleConfig(
            position: .right,
            emoji: "❤️",
            windLevel: .none,
            displayDuration: 3.0
        )
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            speechBubbleVisible = true
        }
    }

    private func revealButtons() {
        guard !reviewRequested else { return }
        reviewRequested = true
        Task {
            try? await Task.sleep(for: .seconds(0.3))
            requestReview()
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation { showButtons = true }
        }
    }

    // MARK: - Lifecycle

    private func handleAppear() {
        analytics.send(.onboardingScreenViewed(step: "review"))
        eyesOverride = "happy"

        if skipAnimation {
            showSecondLine = true
            textCompleted = true
            showButtons = true
        }
    }
}

#if DEBUG
#Preview {
    OnboardingStepPreview(showBlob: true, showWind: false) { _, _, eyesOverride, _ in
        OnboardingReviewStep(
            skipAnimation: false,
            onContinue: {},
            eyesOverride: eyesOverride,
            speechBubbleConfig: .constant(nil),
            speechBubbleVisible: .constant(false),
            reactionTrigger: .constant(nil)
        )
        .environment(PetManager())
    }
}
#endif
