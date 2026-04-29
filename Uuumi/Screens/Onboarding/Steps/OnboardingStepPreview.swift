import SwiftUI

#if DEBUG
/// Reusable preview wrapper that provides a fully reactive onboarding environment.
/// Background, wind lines, and island all respond to binding changes from the step.
struct OnboardingStepPreview<Content: View>: View {
    @State var windProgress: CGFloat
    @State var eyesOverride: String?
    @State var showBlob: Bool
    @State var showThoughtBubble: Bool

    // Blow away state
    @State var blowAwayOffsetX: CGFloat = 0
    @State var blowAwayRotation: CGFloat = 0
    @State var windDirection: CGFloat = 1.0
    @State var windBurstActive: Bool = false

    let showWind: Bool
    let showIsland: Bool
    let content: (GeometryProxy, Binding<CGFloat>, Binding<String?>, Binding<Bool>) -> Content

    init(
        windProgress: CGFloat = 0,
        eyesOverride: String? = nil,
        showBlob: Bool = true,
        showWind: Bool = false,
        showIsland: Bool = true,
        showThoughtBubble: Bool = false,
        @ViewBuilder content: @escaping (GeometryProxy, Binding<CGFloat>, Binding<String?>, Binding<Bool>) -> Content
    ) {
        self._windProgress = State(initialValue: windProgress)
        self._eyesOverride = State(initialValue: eyesOverride)
        self._showBlob = State(initialValue: showBlob)
        self._showThoughtBubble = State(initialValue: showThoughtBubble)
        self.showWind = showWind
        self.showIsland = showIsland
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                OnboardingBackgroundView()

                if showWind {
                    WindLinesView(
                        windProgress: windProgress,
                        direction: windDirection,
                        windAreaTop: 0.08,
                        windAreaBottom: 0.42,
                        overrideConfig: windBurstActive ? .burst : nil
                    )
                    .allowsHitTesting(false)
                }

                if showIsland {
                    OnboardingIslandView(
                        screenHeight: geometry.size.height,
                        pet: Blob.shared,
                        petOpacity: showBlob ? 1.0 : 0.0,
                        windProgress: windProgress,
                        eyesOverride: eyesOverride,
                        showThoughtBubble: showThoughtBubble,
                        blowAwayOffsetX: blowAwayOffsetX,
                        blowAwayRotation: blowAwayRotation
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(.container, edges: .bottom)
                }

                content(geometry, $windProgress, $eyesOverride, $showThoughtBubble)
            }
        }
        .environment(AnalyticsManager())
    }
}
#endif
