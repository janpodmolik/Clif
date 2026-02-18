import SwiftUI

struct OnboardingIslandStep: View {
    @State private var showSecondLine = false
    @State private var showThirdLine = false

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                narrativeText

                Spacer()

                IslandBase(screenHeight: geometry.size.height)
            }
            .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    private var narrativeText: some View {
        VStack(spacing: 12) {
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
                    }
                }
            )
            .opacity(showSecondLine ? 1 : 0)

            Text("But it's empty.")
                .font(AppFont.quicksand(.title2, weight: .semiBold))
                .padding(.top, 12)
                .opacity(showThirdLine ? 1 : 0)
        }
        .font(AppFont.quicksand(.title3, weight: .medium))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
    }
}

#if DEBUG
#Preview {
    OnboardingView()
}
#endif
