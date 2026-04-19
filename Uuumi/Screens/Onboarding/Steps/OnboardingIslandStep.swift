import SwiftUI

struct OnboardingIslandStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void

    @Environment(\.onboardingFontScale) private var fontScale

    @State private var showSecondLine = false
    @State private var showThirdLine = false
    @State private var textCompleted = false
    @State private var narrativeBeat = 0

    // MARK: - Narrative Text
    private let narrativeLine1 = "Somewhere, a tiny island floats in the sky..."
    private let narrativeLine2 = "A peaceful place, untouched by the chaos below."
    private let narrativeLine3 = "But it's empty."

    var body: some View {
        Color.clear
            .overlay(alignment: .top) {
                narrative
                    .padding(.horizontal, 32)
                    .padding(.top, 60)
            }
            .overlay(alignment: .bottom) {
                if textCompleted || skipAnimation {
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
                        onCompleted: { showSecondLine = true }
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
                            Task {
                                if narrativeBeat < 2 {
                                    try? await Task.sleep(for: .seconds(1.0))
                                }
                                withAnimation(.easeIn(duration: narrativeBeat >= 2 ? 0.3 : 0.6)) {
                                    showThirdLine = true
                                }
                                withAnimation(.easeOut(duration: narrativeBeat >= 2 ? 0.3 : 0.4)) {
                                    textCompleted = true
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
            .foregroundStyle(.primary)
            .padding(.top, 20)
        }
        .font(AppFont.quicksandOnboarding(.title3, weight: .medium, scale: fontScale))
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
}

#if DEBUG
#Preview {
    OnboardingStepPreview(showBlob: false) { _, _, _, _ in
        OnboardingIslandStep(
            skipAnimation: false,
            onContinue: {}
        )
    }
}
#endif
