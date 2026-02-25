import SwiftUI

struct OnboardingIslandStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void

    @State private var showSecondLine = false
    @State private var showThirdLine = false
    @State private var textCompleted = false
    @State private var narrativeBeat = 0

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
            if skipAnimation {
                Text("Somewhere, a tiny island floats in the sky...")
                Text("A peaceful place, untouched by the chaos below.")
                Text("But it's empty.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
                    .foregroundStyle(.primary)
                    .padding(.top, 20)
            } else {
                let skipped = narrativeBeat >= 1

                TypewriterText(
                    text: "Somewhere, a tiny island floats in the sky...",
                    skipRequested: skipped,
                    onCompleted: { showSecondLine = true }
                )

                TypewriterText(
                    text: "A peaceful place, untouched by the chaos below.",
                    active: showSecondLine,
                    skipRequested: narrativeBeat >= 2,
                    onCompleted: {
                        Task {
                            if narrativeBeat < 2 {
                                try? await Task.sleep(for: .seconds(1.0))
                            }
                            withAnimation(.easeIn(duration: skipped ? 0.3 : 0.6)) {
                                showThirdLine = true
                            }
                            withAnimation(.easeOut(duration: skipped ? 0.3 : 0.4)) {
                                textCompleted = true
                            }
                        }
                    }
                )
                .opacity(showSecondLine ? 1 : 0)

                Text("But it's empty.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
                    .foregroundStyle(.primary)
                    .opacity(showThirdLine ? 1 : 0)
                    .padding(.top, 20)
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
}

#if DEBUG
#Preview {
    GeometryReader { geometry in
        ZStack {
            OnboardingBackgroundView()
            IslandBase(screenHeight: geometry.size.height)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.container, edges: .bottom)
            OnboardingIslandStep(
                skipAnimation: false,
                onContinue: {}
            )
        }
    }
}
#endif
