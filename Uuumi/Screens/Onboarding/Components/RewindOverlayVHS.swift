import SwiftUI

/// VHS-style rewind overlay with horizontal scan lines, tracking noise, and pulsing "REWIND" text.
struct RewindOverlayVHS: View {
    let isVisible: Bool

    @Environment(\.onboardingFontScale) private var fontScale

    @State private var isTextPulsing = false
    @State private var scanLineOffset: CGFloat = 0
    @State private var noiseBarOffset: CGFloat = -100
    @State private var showNoiseBars = false
    @State private var screenTint: CGFloat = 0
    @State private var noiseTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            // Blue/cyan tint wash
            Color.cyan.opacity(screenTint)
                .ignoresSafeArea()

            // Scan lines
            scanLines
                .ignoresSafeArea()

            // VHS tracking noise bars
            if showNoiseBars {
                trackingNoise
                    .ignoresSafeArea()
            }

            // REWIND label
            rewindLabel
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 80)
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: isVisible)
        .allowsHitTesting(false)
        .onChange(of: isVisible) { _, newValue in
            if newValue {
                startVHSEffect()
            } else {
                noiseTask?.cancel()
                noiseTask = nil
                isTextPulsing = false
                showNoiseBars = false
                screenTint = 0
            }
        }
    }

    // MARK: - Scan Lines

    private var scanLines: some View {
        GeometryReader { geometry in
            let lineSpacing: CGFloat = 3
            let lineCount = Int(geometry.size.height / lineSpacing) + 1

            Canvas { context, size in
                for i in 0..<lineCount {
                    let y = CGFloat(i) * lineSpacing + scanLineOffset.truncatingRemainder(dividingBy: lineSpacing)
                    let rect = CGRect(x: 0, y: y, width: size.width, height: 1.5)
                    context.fill(Path(rect), with: .color(.white.opacity(0.12)))
                }
            }
        }
    }

    // MARK: - Tracking Noise

    private var trackingNoise: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Noise band — horizontal distortion bar
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.15),
                                .white.opacity(0.25),
                                .white.opacity(0.15),
                                .clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 30)
            }
            .offset(y: noiseBarOffset)
        }
    }

    // MARK: - Label

    private var rewindLabel: some View {
        HStack(spacing: 8) {
            Image(systemName: "backward.fill")
                .font(.title3.weight(.bold))
            Text("REWIND")
                .font(AppFont.quicksandOnboarding(.title2, weight: .bold, scale: fontScale))
                .tracking(4)
        }
        .foregroundStyle(.white)
        .opacity(isTextPulsing ? 1.0 : 0.2)
        .animation(
            .easeInOut(duration: 0.35).repeatForever(autoreverses: true),
            value: isTextPulsing
        )
    }

    // MARK: - VHS Effect Sequence

    private func startVHSEffect() {
        // Tint wash
        withAnimation(.easeIn(duration: 0.3)) {
            screenTint = 0.1
        }

        // Scan line scroll
        withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
            scanLineOffset = 200
        }

        // Text pulse
        isTextPulsing = true

        // Tracking noise bars — periodic sweeps
        showNoiseBars = true
        noiseTask?.cancel()
        noiseTask = Task {
            while !Task.isCancelled {
                noiseBarOffset = -40
                withAnimation(.linear(duration: 1.5)) {
                    noiseBarOffset = UIScreen.main.bounds.height + 40
                }
                try? await Task.sleep(for: .seconds(Double.random(in: 1.8...3.0)))
            }
        }
    }
}

#if DEBUG
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        RewindOverlayVHS(isVisible: true)
    }
}
#endif
