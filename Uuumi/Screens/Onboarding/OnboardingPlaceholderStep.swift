import SwiftUI

struct OnboardingPlaceholderStep: View {
    let screen: OnboardingScreen

    private var actColor: Color {
        switch screen.act {
        case .story: .blue
        case .demo: .orange
        case .setup: .green
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("ACT \(screen.act.rawValue)")
                .font(.caption.weight(.bold))
                .foregroundStyle(actColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(actColor.opacity(0.15), in: .capsule)

            Text(screen.title)
                .font(.title.bold())

            Text(screen.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Text("Screen \(screen.rawValue + 1) of \(OnboardingScreen.totalCount)")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#if DEBUG
#Preview {
    OnboardingPlaceholderStep(screen: .villain)
}
#endif
