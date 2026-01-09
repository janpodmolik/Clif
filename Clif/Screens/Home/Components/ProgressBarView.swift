import SwiftUI

struct ProgressBarView: View {
    let progress: Double

    private let trackHeight: CGFloat = 4

    private var progressColor: Color {
        switch progress {
        case 0..<0.5:
            return .green
        case 0.5..<0.8:
            return .orange
        default:
            return .red
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.primary.opacity(0.15))
                    .frame(height: trackHeight)

                RoundedRectangle(cornerRadius: 2)
                    .fill(progressColor)
                    .frame(width: geometry.size.width * min(progress, 1.0), height: trackHeight)
            }
        }
        .frame(height: trackHeight)
        .animation(.easeInOut(duration: 0.3), value: progress)
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
