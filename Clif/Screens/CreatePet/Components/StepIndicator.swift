import SwiftUI

struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int

    private enum Layout {
        static let dotSize: CGFloat = 8
        static let activeDotSize: CGFloat = 10
        static let spacing: CGFloat = 8
    }

    var body: some View {
        HStack(spacing: Layout.spacing) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Circle()
                    .fill(index == currentStep ? Color.primary : Color.secondary.opacity(0.4))
                    .frame(
                        width: index == currentStep ? Layout.activeDotSize : Layout.dotSize,
                        height: index == currentStep ? Layout.activeDotSize : Layout.dotSize
                    )
                    .animation(.easeInOut(duration: 0.2), value: currentStep)
            }
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        StepIndicator(currentStep: 0, totalSteps: 5)
        StepIndicator(currentStep: 2, totalSteps: 5)
        StepIndicator(currentStep: 4, totalSteps: 5)
    }
}
#endif
