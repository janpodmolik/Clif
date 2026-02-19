import SwiftUI

struct OnboardingNarrativeView: View {
    let screen: OnboardingScreen
    var skipAnimation: Bool = false
    var onTextCompleted: (() -> Void)?

    var body: some View {
        Group {
            switch screen {
            case .island:
                islandNarrative
            case .meetPet:
                meetPetNarrative
            case .villain:
                villainNarrative
            default:
                EmptyView()
            }
        }
        .font(AppFont.quicksand(.title3, weight: .medium))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .id(screen)
        .transition(.opacity)
    }

    // MARK: - Screen 1: The Island

    @State private var showIslandSecondLine = false
    @State private var showIslandThirdLine = false

    private var islandNarrative: some View {
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
                    onCompleted: { showIslandSecondLine = true }
                )

                TypewriterText(
                    text: "A peaceful place, untouched by the chaos below.",
                    active: showIslandSecondLine,
                    onCompleted: {
                        Task {
                            try? await Task.sleep(for: .seconds(1.0))
                            withAnimation(.easeIn(duration: 0.6)) {
                                showIslandThirdLine = true
                            }
                            onTextCompleted?()
                        }
                    }
                )
                .opacity(showIslandSecondLine ? 1 : 0)

                Text("But it's empty.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
                    .padding(.top, 12)
                    .opacity(showIslandThirdLine ? 1 : 0)
            }
        }
    }

    // MARK: - Screen 2: Meet Uuumi

    @State private var showMeetSecondLine = false

    private var meetPetNarrative: some View {
        VStack(spacing: 12) {
            if skipAnimation {
                Text("Meet Uuumi.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
                Text("A tiny creature looking for somewhere to grow.")
            } else {
                TypewriterText(
                    text: "Meet Uuumi.",
                    onCompleted: {
                        Task {
                            try? await Task.sleep(for: .seconds(0.5))
                            withAnimation { showMeetSecondLine = true }
                        }
                    }
                )
                .font(AppFont.quicksand(.title2, weight: .semiBold))

                TypewriterText(
                    text: "A tiny creature looking for somewhere to grow.",
                    active: showMeetSecondLine,
                    onCompleted: { onTextCompleted?() }
                )
                .opacity(showMeetSecondLine ? 1 : 0)
            }
        }
    }

    // MARK: - Screen 3: Dr. Doomscroll

    @State private var showVillainSecondLine = false
    @State private var showVillainThirdLine = false

    private var villainNarrative: some View {
        VStack(spacing: 12) {
            if skipAnimation {
                Text("But the skies aren't safe.")
                Text("Dr. Doomscroll lurks in the winds. The more you scroll, the harder he blows.")
                Text("If the wind gets too strong... Uuumi gets blown away.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
                    .padding(.top, 12)
            } else {
                TypewriterText(
                    text: "But the skies aren't safe.",
                    onCompleted: {
                        Task {
                            try? await Task.sleep(for: .seconds(0.5))
                            withAnimation { showVillainSecondLine = true }
                        }
                    }
                )

                TypewriterText(
                    text: "Dr. Doomscroll lurks in the winds. The more you scroll, the harder he blows.",
                    active: showVillainSecondLine,
                    onCompleted: {
                        Task {
                            try? await Task.sleep(for: .seconds(0.8))
                            withAnimation(.easeIn(duration: 0.6)) {
                                showVillainThirdLine = true
                            }
                            onTextCompleted?()
                        }
                    }
                )
                .opacity(showVillainSecondLine ? 1 : 0)

                Text("If the wind gets too strong... Uuumi gets blown away.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
                    .padding(.top, 12)
                    .opacity(showVillainThirdLine ? 1 : 0)
            }
        }
    }
}

#if DEBUG
#Preview("Island") {
    ZStack {
        Color.blue.opacity(0.2)
        OnboardingNarrativeView(screen: .island)
    }
}

#Preview("Meet Pet") {
    ZStack {
        Color.blue.opacity(0.2)
        OnboardingNarrativeView(screen: .meetPet)
    }
}

#Preview("Villain") {
    ZStack {
        Color.blue.opacity(0.2)
        OnboardingNarrativeView(screen: .villain)
    }
}
#endif
