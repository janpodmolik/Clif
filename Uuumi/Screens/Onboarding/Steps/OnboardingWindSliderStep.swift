import SwiftUI

struct OnboardingWindSliderStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void

    @Binding var windProgress: CGFloat
    @Binding var eyesOverride: String?

    @State private var narrativeBeat = 0
    @State private var showSecondLine = false
    @State private var textCompleted = false
    @State private var hasInteracted = false
    @State private var lastHapticLevel: WindLevel = .none
    @State private var selectionGenerator = UISelectionFeedbackGenerator()

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
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !textCompleted, !skipAnimation else { return }
                    HapticType.impactLight.trigger()
                    narrativeBeat += 1
                }

            Spacer()

            sliderArea
                .padding(.horizontal, 24)

            Spacer()
                .frame(height: 16)

            continueButton
                .padding(.horizontal, 24)
                .opacity(hasInteracted ? 1 : 0)
                .animation(.easeOut(duration: 0.3), value: hasInteracted)
        }
        .onAppear {
            if skipAnimation {
                textCompleted = true
                showSecondLine = true
                hasInteracted = true
                windProgress = 0.5
                eyesOverride = WindLevel.from(progress: 0.5).eyes
            } else {
                windProgress = 0
                eyesOverride = "happy"
            }
        }
        .onDisappear {
            windProgress = 0.6
            eyesOverride = WindLevel.from(progress: 0.6).eyes
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

                // Thumb
                Circle()
                    .fill(.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
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
                        }
                    }
            )
        }
        .frame(height: 36)
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
    GeometryReader { geometry in
        ZStack {
            OnboardingBackgroundView()
            WindLinesView(
                windProgress: 0.5,
                direction: 1.0,
                windAreaTop: 0.08,
                windAreaBottom: 0.42
            )
            .allowsHitTesting(false)
            OnboardingIslandView(
                screenHeight: geometry.size.height,
                pet: Blob.shared,
                windProgress: 0.5,
                eyesOverride: "neutral"
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea(.container, edges: .bottom)
            OnboardingWindSliderStep(
                skipAnimation: false,
                onContinue: {},
                windProgress: .constant(0.5),
                eyesOverride: .constant(nil)
            )
        }
    }
}
#endif
