import SwiftUI

struct OnboardingWindSliderStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void

    @Binding var windProgress: CGFloat
    @Binding var eyesOverride: String?
    @Binding var blowAwayOffsetX: CGFloat
    @Binding var blowAwayRotation: CGFloat
    @Binding var windDirection: CGFloat
    @Binding var windBurstActive: Bool

    @Environment(\.onboardingFontScale) private var fontScale

    // MARK: - Phase

    private enum SliderPhase {
        case slider
        case blowAway
        case rewind
        case done
    }

    @State private var phase: SliderPhase = .slider

    // MARK: - Narrative State

    @State private var narrativeBeat = 0
    @State private var showSecondLine = false
    @State private var textCompleted = false

    // Blow away narrative
    @State private var showBlowAwayText = false
    @State private var showBlowAwayLine1 = false
    @State private var showBlowAwayLine2 = false
    @State private var blowAwayBeat = 0

    // Post-rewind narrative
    @State private var showPostRewindLine1 = false
    @State private var showPostRewindLine2 = false
    @State private var postRewindBeat = 0
    @State private var postRewindTextCompleted = false

    // MARK: - Slider State

    @State private var hasInteracted = false
    @State private var lastHapticLevel: WindLevel = .none
    @State private var selectionGenerator = UISelectionFeedbackGenerator()
    @State private var thumbPulsing = false
    @State private var showSlider = false
    @State private var showDragHint = false
    @State private var dragHintPulsing = false

    // MARK: - Rewind State

    @State private var showRewindButton = false
    @State private var rewindOverlayVisible = false
    @State private var animationTask: Task<Void, Never>?

    private var windLevel: WindLevel {
        WindLevel.from(progress: windProgress)
    }

    private var windLabel: String {
        switch windLevel {
        case .none: "A calm day."
        case .low: "A little breezy..."
        case .medium: "Uuumi is struggling."
        case .high: "Too much. Uuumi can't hold on."
        }
    }

    private var sliderColor: Color {
        switch windLevel {
        case .none: .green
        case .low: .green
        case .medium: .orange
        case .high: .red
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width

            VStack(spacing: 0) {
                narrativeArea
                    .padding(.horizontal, 32)
                    .padding(.top, 60)

                Spacer()

                if showSlider && phase == .slider {
                    sliderArea
                        .padding(.horizontal, 24)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()
                    .frame(height: 16)

                bottomArea
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
            .overlay {
                if !textCompleted && !skipAnimation && phase == .slider {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticType.impactLight.trigger()
                            narrativeBeat += 1
                        }
                }

                if phase == .done && !postRewindTextCompleted && !skipAnimation {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            HapticType.impactLight.trigger()
                            postRewindBeat += 1
                        }
                }
            }
            .overlay {
                RewindOverlayVHS(isVisible: rewindOverlayVisible)
                    .allowsHitTesting(false)
            }
            .onAppear {
                handleAppear()
            }
            .onChange(of: textCompleted) { _, completed in
                if completed && !hasInteracted {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSlider = true
                    }
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        thumbPulsing = true
                    }
                    withAnimation(.easeOut(duration: 0.3)) {
                        showDragHint = true
                    }
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        dragHintPulsing = true
                    }
                }
            }
            .onChange(of: windProgress) { _, newValue in
                eyesOverride = WindLevel.from(progress: newValue).eyes

                if newValue >= 0.95 && phase == .slider && hasInteracted {
                    triggerBlowAway(screenWidth: screenWidth)
                }
            }
            .onDisappear {
                animationTask?.cancel()
                animationTask = nil

                eyesOverride = WindLevel.from(progress: windProgress).eyes

                // Reset blow away visual state
                blowAwayOffsetX = 0
                blowAwayRotation = 0
                windDirection = 1.0
                windBurstActive = false
            }
        }
    }

    // MARK: - Narrative

    @ViewBuilder
    private var narrativeArea: some View {
        switch phase {
        case .slider:
            sliderNarrative
                .transition(.opacity)
        case .blowAway:
            blowAwayNarrative
                .transition(.opacity)
        case .rewind:
            EmptyView()
        case .done:
            postRewindNarrative
                .transition(.opacity)
        }
    }

    private var sliderNarrative: some View {
        VStack(spacing: 12) {
            if skipAnimation {
                Text("This is what happens when you scroll.")
                Text("Drag to feel Uuumi's world change.")
                    .font(AppFont.quicksandOnboarding(.title2, weight: .semiBold, scale: fontScale))
                    .padding(.top, 12)
            } else {
                let skipped = narrativeBeat >= 1

                TypewriterText(
                    text: "This is what happens when you scroll.",
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
                    text: "Drag to feel Uuumi's world change.",
                    active: showSecondLine,
                    skipRequested: narrativeBeat >= 2,
                    onCompleted: {
                        textCompleted = true
                    }
                )
                .font(AppFont.quicksandOnboarding(.title2, weight: .semiBold, scale: fontScale))
                .opacity(showSecondLine ? 1 : 0)
                .padding(.top, 12)
            }
        }
        .font(AppFont.quicksandOnboarding(.title3, weight: .medium, scale: fontScale))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
    }

    private var blowAwayNarrative: some View {
        VStack(spacing: 12) {
            if showBlowAwayText {
                TypewriterText(
                    text: "Too much.",
                    skipRequested: blowAwayBeat >= 1,
                    onCompleted: {
                        Task {
                            try? await Task.sleep(for: .seconds(0.6))
                            withAnimation(.easeIn(duration: 0.5)) { showBlowAwayLine2 = true }
                        }
                    }
                )
                .font(AppFont.quicksandOnboarding(.title2, weight: .medium, scale: fontScale))
                .foregroundStyle(.secondary)

                if showBlowAwayLine2 {
                    Text("Uuumi is gone.")
                        .font(AppFont.quicksandOnboarding(.title, weight: .semiBold, scale: fontScale))
                        .padding(.top, 8)
                        .transition(.opacity)
                }
            }
        }
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
    }

    private var postRewindNarrative: some View {
        VStack(spacing: 12) {
            if skipAnimation {
                Text("This was just practice.")
                Text("Out there, there's no rewind.")
                    .font(AppFont.quicksandOnboarding(.title2, weight: .semiBold, scale: fontScale))
                    .padding(.top, 12)
            } else {
                TypewriterText(
                    text: "This was just practice.",
                    active: showPostRewindLine1,
                    skipRequested: postRewindBeat >= 1,
                    onCompleted: {
                        Task {
                            if postRewindBeat < 1 {
                                try? await Task.sleep(for: .seconds(0.5))
                            }
                            withAnimation { showPostRewindLine2 = true }
                        }
                    }
                )
                .opacity(showPostRewindLine1 ? 1 : 0)

                TypewriterText(
                    text: "Out there, there's no rewind.",
                    active: showPostRewindLine2,
                    skipRequested: postRewindBeat >= 2,
                    onCompleted: {
                        postRewindTextCompleted = true
                    }
                )
                .font(AppFont.quicksandOnboarding(.title2, weight: .semiBold, scale: fontScale))
                .opacity(showPostRewindLine2 ? 1 : 0)
                .padding(.top, 12)
            }
        }
        .font(AppFont.quicksandOnboarding(.title3, weight: .medium, scale: fontScale))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Slider Area

    private var sliderArea: some View {
        VStack(spacing: 16) {
            Text(windLabel)
                .font(AppFont.quicksandOnboarding(.body, weight: .medium, scale: fontScale))
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.2), value: windLevel)

            windSlider
        }
    }

    // MARK: - Wind Slider

    private var windSlider: some View {
        GeometryReader { geometry in
            let trackHeight: CGFloat = 16
            let thumbSize: CGFloat = 36
            let usableWidth = geometry.size.width - thumbSize
            let thumbX = thumbSize / 2 + usableWidth * windProgress

            ZStack(alignment: .leading) {
                // Track background
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(Color.primary.opacity(0.1))
                    .frame(height: trackHeight)

                // Filled track with wave
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: trackHeight / 2)
                        .fill(sliderColor.opacity(0.6))

                    OnboardingWaveLayer(direction: -1)
                        .clipShape(RoundedRectangle(cornerRadius: trackHeight / 2))
                }
                .frame(width: max(trackHeight, thumbX), height: trackHeight)
                .animation(.easeInOut(duration: 0.15), value: sliderColor)

                // Thumb + drag hint
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: thumbSize, height: thumbSize)
                        .scaleEffect(thumbPulsing ? 1.15 : 1.0)
                        .shadow(color: .black.opacity(thumbPulsing ? 0.2 : 0.12), radius: thumbPulsing ? 8 : 6, y: 2)

                    if showDragHint {
                        dragHintOverlay
                            .offset(y: -44)
                            .transition(.opacity.animation(.easeOut(duration: 0.3)))
                    }
                }
                .position(x: thumbX, y: geometry.size.height / 2)
            }
            .frame(height: thumbSize)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard phase == .slider else { return }

                        let fingerFraction = (value.location.x - thumbSize / 2) / usableWidth
                        windProgress = Self.applyDragResistance(to: min(max(fingerFraction, 0), 1))

                        selectionGenerator.selectionChanged()

                        let currentLevel = WindLevel.from(progress: windProgress)
                        if currentLevel != lastHapticLevel {
                            lastHapticLevel = currentLevel
                            HapticType.impactMedium.trigger()
                        }

                        if !hasInteracted {
                            hasInteracted = true
                            withAnimation(.easeOut(duration: 0.3)) {
                                thumbPulsing = false
                                showDragHint = false
                            }
                        }
                    }
            )
        }
        .frame(height: 36)
    }

    // MARK: - Drag Hint

    private var dragHintOverlay: some View {
        Image(systemName: "hand.draw.fill")
            .font(.title3)
            .foregroundStyle(.primary)
            .scaleEffect(dragHintPulsing ? 1.1 : 1.0)
            .opacity(dragHintPulsing ? 1.0 : 0.5)
            .allowsHitTesting(false)
    }

    // MARK: - Bottom Area

    @ViewBuilder
    private var bottomArea: some View {
        switch phase {
        case .slider:
            // No button — blow away triggers automatically at 0.95
            Color.clear.frame(height: 50)

        case .blowAway:
            if showRewindButton {
                rewindButton
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Color.clear.frame(height: 50)
            }

        case .rewind:
            Color.clear.frame(height: 50)

        case .done:
            continueButton
                .opacity(postRewindTextCompleted || skipAnimation ? 1 : 0)
                .animation(.easeOut(duration: 0.3), value: postRewindTextCompleted)
        }
    }

    private var rewindButton: some View {
        Button {
            HapticType.notificationSuccess.trigger()
            triggerRewind()
        } label: {
            Label("Rewind", systemImage: "backward.fill")
        }
        .buttonStyle(.primary)
    }

    private var continueButton: some View {
        Button {
            HapticType.impactLight.trigger()
            onContinue()
        } label: {
            Text("Continue")
        }
        .buttonStyle(.primary)
    }

    // MARK: - Drag Resistance

    /// Maps linear finger position (0–1) to windProgress with progressive resistance above 0.5.
    /// Below threshold: 1:1 linear response. Above: blend of linear (floor) + power curve creates
    /// gradual resistance — thumb always moves with finger, but progressively less the closer
    /// to blow-away. `linearFloor` guarantees non-zero slope so the slider never feels stuck.
    private static func applyDragResistance(to fingerFraction: CGFloat) -> CGFloat {
        let resistanceStart: CGFloat = 0.5
        let linearFloor: CGFloat = 0.2
        let curveWeight: CGFloat = 0.8
        let resistanceExponent: CGFloat = 3.0

        if fingerFraction <= resistanceStart {
            return fingerFraction
        }

        let excess = (fingerFraction - resistanceStart) / (1 - resistanceStart)
        let eased = linearFloor * excess + curveWeight * pow(excess, resistanceExponent)
        return resistanceStart + eased * (1 - resistanceStart)
    }

    // MARK: - Appear

    private func handleAppear() {
        let initial = OnboardingScreen.windSlider.initialWindProgress ?? 0.1
        windProgress = initial
        eyesOverride = WindLevel.from(progress: initial).eyes

        if skipAnimation {
            textCompleted = true
            showSecondLine = true
            showSlider = true
            hasInteracted = true
            phase = .done
            showPostRewindLine1 = true
            showPostRewindLine2 = true
            postRewindTextCompleted = true
            windProgress = 1.0
            eyesOverride = WindLevel.from(progress: 1.0).eyes
        }
    }

    // MARK: - Blow Away

    private func triggerBlowAway(screenWidth: CGFloat) {
        phase = .blowAway

        // Lock slider value at 1.0
        windProgress = 1.0
        eyesOverride = "scared"

        animationTask?.cancel()
        animationTask = Task {
            // Brief pause before blow away
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }

            // Wind burst
            windBurstActive = true
            HapticType.notificationError.trigger()

            // Pet flies off-screen
            withAnimation(.easeIn(duration: BlowAwayConfig.default.duration)) {
                blowAwayOffsetX = screenWidth + 150
                blowAwayRotation = BlowAwayConfig.default.rotationDegrees
            }

            // After blow away completes
            try? await Task.sleep(for: .seconds(BlowAwayConfig.default.duration + 0.3))
            guard !Task.isCancelled else { return }
            windBurstActive = false

            // Show narrative
            withAnimation(.easeOut(duration: 0.4)) {
                showBlowAwayText = true
                showBlowAwayLine1 = true
            }

            // Show rewind button after delay
            try? await Task.sleep(for: .seconds(1.5))
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showRewindButton = true
            }
        }
    }

    // MARK: - Rewind

    private func triggerRewind() {
        phase = .rewind
        showRewindButton = false
        showBlowAwayText = false

        // Show overlay + reverse wind direction
        rewindOverlayVisible = true
        windDirection = -1.0

        animationTask?.cancel()
        animationTask = Task {
            // Pet flies back
            withAnimation(.easeOut(duration: 1.0)) {
                blowAwayOffsetX = 0
                blowAwayRotation = 0
            }

            // Wind stays at 1.0 during rewind
            try? await Task.sleep(for: .seconds(1.0))
            guard !Task.isCancelled else { return }

            // Hide overlay, restore wind direction
            try? await Task.sleep(for: .seconds(0.2))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.3)) {
                rewindOverlayVisible = false
            }
            windDirection = 1.0

            // Transition to done phase
            try? await Task.sleep(for: .seconds(0.3))
            guard !Task.isCancelled else { return }
            eyesOverride = WindLevel.from(progress: windProgress).eyes

            withAnimation(.easeOut(duration: 0.3)) {
                phase = .done
                showPostRewindLine1 = true
            }
        }
    }
}

// MARK: - Wave Layer (matches WindProgressBar style)

private struct OnboardingWaveLayer: View {
    let direction: CGFloat

    @State private var wavePhase: CGFloat = 0

    var body: some View {
        OnboardingWaveShape(phase: wavePhase, amplitude: 2.5, frequency: 4)
            .fill(Color.white.opacity(0.2))
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    wavePhase = direction * .pi * 2
                }
            }
    }
}

private struct OnboardingWaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    var frequency: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY

        path.move(to: CGPoint(x: 0, y: midY))

        for x in stride(from: 0, through: rect.width, by: 2) {
            let relativeX = x / rect.width
            let y = midY + sin(relativeX * .pi * frequency + phase) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}

#if DEBUG
private struct WindSliderPreview: View {
    @State var windProgress: CGFloat = 0.1
    @State var eyesOverride: String?
    @State var blowAwayOffsetX: CGFloat = 0
    @State var blowAwayRotation: CGFloat = 0
    @State var windDirection: CGFloat = 1.0
    @State var windBurstActive = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                OnboardingBackgroundView()

                WindLinesView(
                    windProgress: windProgress,
                    direction: windDirection,
                    windAreaTop: 0.08,
                    windAreaBottom: 0.42,
                    overrideConfig: windBurstActive ? .burst : nil
                )
                .allowsHitTesting(false)

                OnboardingIslandView(
                    screenHeight: geometry.size.height,
                    pet: Blob.shared,
                    windProgress: windProgress,
                    eyesOverride: eyesOverride,
                    blowAwayOffsetX: blowAwayOffsetX,
                    blowAwayRotation: blowAwayRotation
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.container, edges: .bottom)

                OnboardingWindSliderStep(
                    skipAnimation: false,
                    onContinue: {},
                    windProgress: $windProgress,
                    eyesOverride: $eyesOverride,
                    blowAwayOffsetX: $blowAwayOffsetX,
                    blowAwayRotation: $blowAwayRotation,
                    windDirection: $windDirection,
                    windBurstActive: $windBurstActive
                )
            }
        }
    }
}

#Preview {
    WindSliderPreview()
}
#endif
