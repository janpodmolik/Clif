import SwiftUI

// MARK: - Wind Progress Bar

struct WindProgressBar: View {
    let progress: Double
    var isPulsing: Bool = false

    @State private var showPulsingWave = false

    private let trackHeight: CGFloat = 12

    private var baseColor: Color {
        if isPulsing { return .cyan }
        if progress < 0.6 { return .green }
        if progress < 0.8 { return .orange }
        return .red
    }

    var body: some View {
        GeometryReader { geometry in
            let progressWidth = geometry.size.width * min(max(progress, 0), 1.0)

            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(Color.primary.opacity(0.1))

                // Base layer
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(baseColor.opacity(0.6))
                    .frame(width: progressWidth)

                // Normal wave (flows left = increasing wind)
                WaveLayer(direction: -1)
                    .frame(width: progressWidth, height: trackHeight)
                    .clipShape(RoundedRectangle(cornerRadius: trackHeight / 2))
                    .opacity(showPulsingWave ? 0 : 1)

                // Pulsing wave (flows right = decreasing wind)
                WaveLayer(direction: 1)
                    .frame(width: progressWidth, height: trackHeight)
                    .clipShape(RoundedRectangle(cornerRadius: trackHeight / 2))
                    .opacity(showPulsingWave ? 1 : 0)
            }
            .animation(.easeInOut(duration: 0.3), value: progress)
        }
        .frame(height: trackHeight)
        .onAppear {
            showPulsingWave = isPulsing
        }
        .onChange(of: isPulsing) { _, newValue in
            withAnimation(.easeInOut(duration: 0.4)) {
                showPulsingWave = newValue
            }
        }
    }
}

// MARK: - Wave Layer

private struct WaveLayer: View {
    let direction: CGFloat

    @State private var wavePhase: CGFloat = 0

    var body: some View {
        WaveShape(phase: wavePhase, amplitude: 2, frequency: 4)
            .fill(Color.white.opacity(0.2))
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    wavePhase = direction * .pi * 2
                }
            }
    }
}

// MARK: - Wave Shape

private struct WaveShape: Shape {
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
