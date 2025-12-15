import SwiftUI

struct ProgressBarView: View {
    let progress: Double

    private let trackHeight: CGFloat = 4
    private let iOSGreenStart = Color(red: 52/255, green: 199/255, blue: 89/255)
    private let iOSGreenEnd = Color(red: 48/255, green: 209/255, blue: 88/255)

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.primary.opacity(0.15))
                    .frame(height: trackHeight)

                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            colors: [iOSGreenStart, iOSGreenEnd],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * min(progress, 1.0), height: trackHeight)
            }
        }
        .frame(height: trackHeight)
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()

        ProgressBarView(progress: 0.27)
            .padding()
    }
}
