import SwiftUI

struct ProgressBarView: View {
    let progress: Double
    var isPulsing: Bool = false

    @State private var pulsePhase = false

    private let trackHeight: CGFloat = 6

    private var progressColor: Color {
        if isPulsing {
            return .cyan
        }
        return progress < 0.8 ? .green : .red
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(0.15))
                    .frame(height: trackHeight)

                RoundedRectangle(cornerRadius: 3)
                    .fill(progressColor)
                    .frame(width: geometry.size.width * min(progress, 1.0), height: trackHeight)
                    .opacity(isPulsing ? (pulsePhase ? 1.0 : 0.4) : 1.0)
                    .animation(
                        isPulsing
                            ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                            : .default,
                        value: pulsePhase
                    )
            }
        }
        .frame(height: trackHeight)
        .animation(.easeInOut(duration: 0.3), value: progress)
        .onChange(of: isPulsing) { _, newValue in
            if newValue {
                pulsePhase = true
            } else {
                pulsePhase = false
            }
        }
        .onAppear {
            if isPulsing {
                pulsePhase = true
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBarView(progress: 0.27)
        ProgressBarView(progress: 0.55)
        ProgressBarView(progress: 0.85)
    }
    .padding()
    .background(Color.blue.opacity(0.1))
}
