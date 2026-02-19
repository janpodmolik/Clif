import SwiftUI

struct OnboardingIslandStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void

    @State private var showSecondLine = false
    @State private var showThirdLine = false
    @State private var textCompleted = false

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
    }

    // MARK: - Narrative

    private var narrative: some View {
        VStack(spacing: 12) {
            if skipAnimation {
                Text("Somewhere, a tiny island floats in the sky...")
                Text("A peaceful place, untouched by the chaos below.")
                Text("But it's empty.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
                    .padding(.top, 12)
            } else {
                TypewriterText(
                    text: "Somewhere, a tiny island floats in the sky...",
                    onCompleted: { showSecondLine = true }
                )

                TypewriterText(
                    text: "A peaceful place, untouched by the chaos below.",
                    active: showSecondLine,
                    onCompleted: {
                        Task {
                            try? await Task.sleep(for: .seconds(1.0))
                            withAnimation(.easeIn(duration: 0.6)) {
                                showThirdLine = true
                            }
                            withAnimation(.easeOut(duration: 0.4)) {
                                textCompleted = true
                            }
                        }
                    }
                )
                .opacity(showSecondLine ? 1 : 0)

                Text("But it's empty.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
                    .padding(.top, 12)
                    .opacity(showThirdLine ? 1 : 0)
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
            DayBackgroundView()
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
