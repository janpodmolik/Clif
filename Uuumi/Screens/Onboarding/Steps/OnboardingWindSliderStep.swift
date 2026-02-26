import SwiftUI

struct OnboardingWindSliderStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void

    @Binding var windProgress: CGFloat
    @Binding var eyesOverride: String?

    /// Minimum wind handed to the lock demo screen on disappear.
    private let minHandoffWind: CGFloat = 0.6

    @State private var narrativeBeat = 0
    @State private var showSecondLine = false
    @State private var textCompleted = false
    @State private var hasInteracted = false
    @State private var lastHapticLevel: WindLevel = .none
    @State private var selectionGenerator = UISelectionFeedbackGenerator()
    @State private var thumbPulsing = false
    @State private var showSlider = false
    @State private var showDragHint = false
    @State private var dragHintPulsing = false

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
        VStack(spacing: 0) {
            narrative
                .padding(.horizontal, 32)
                .padding(.top, 60)

            Spacer()

            if showSlider {
                sliderArea
                    .padding(.horizontal, 24)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Spacer()
                .frame(height: 16)

            continueButton
                .padding(.horizontal, 24)
                .opacity(hasInteracted ? 1 : 0)
                .animation(.easeOut(duration: 0.3), value: hasInteracted)
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
        .onAppear {
            let initial = OnboardingScreen.windSlider.initialWindProgress ?? 0.1
            windProgress = initial
            eyesOverride = WindLevel.from(progress: initial).eyes

            if skipAnimation {
                textCompleted = true
                showSecondLine = true
                showSlider = true
                hasInteracted = true
            }
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
        .onDisappear {
            // Keep user's slider position if it already exceeds the lock demo's entry wind,
            // otherwise ensure minimum medium wind for the lock demo screen
            let lockEntryWind = OnboardingScreen.lockDemo.initialWindProgress ?? 0.7
            if windProgress < lockEntryWind {
                windProgress = minHandoffWind
            }
            eyesOverride = WindLevel.from(progress: windProgress).eyes
        }
        .onChange(of: windProgress) { _, newValue in
            eyesOverride = WindLevel.from(progress: newValue).eyes
        }
    }

    // MARK: - Narrative

    private var narrative: some View {
        VStack(spacing: 12) {
            if skipAnimation {
                Text("This is what happens when you scroll.")
                Text("Drag to feel Uuumi's world change.")
                    .font(AppFont.quicksand(.title2, weight: .semiBold))
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
                .font(AppFont.quicksand(.title2, weight: .semiBold))
                .opacity(showSecondLine ? 1 : 0)
                .padding(.top, 12)
            }
        }
        .font(AppFont.quicksand(.title3, weight: .medium))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
    }

    // MARK: - Slider Area

    private var sliderArea: some View {
        VStack(spacing: 16) {
            Text(windLabel)
                .font(AppFont.quicksand(.body, weight: .medium))
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
                        let fraction = (value.location.x - thumbSize / 2) / usableWidth
                        windProgress = min(max(fraction, 0), 1)

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
#Preview {
    OnboardingStepPreview(windProgress: 0.1, showWind: true) { _, windProgress, eyesOverride in
        OnboardingWindSliderStep(
            skipAnimation: false,
            onContinue: {},
            windProgress: windProgress,
            eyesOverride: eyesOverride
        )
    }
}
#endif
