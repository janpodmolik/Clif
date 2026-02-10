import SwiftUI

struct CreatePetMultiStep: View {
    @Environment(CreatePetCoordinator.self) private var coordinator

    private enum Layout {
        static let footerPadding: CGFloat = 16
        static let footerSpacing: CGFloat = 12
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Step content
                stepContent
                    .frame(maxWidth: .infinity)

                footerBar
            }
            .navigationTitle(coordinator.currentStep.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if coordinator.currentStep.canGoBack {
                        Button {
                            HapticType.impactLight.trigger()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                coordinator.previousStep()
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .dismissButton(placement: .topBarTrailing) {
                coordinator.dismiss()
            }
        }
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch coordinator.currentStep {
        case .appSelection:
            AppSelectionStep()
        case .presetSelection:
            WindPresetStep()
        case .petInfo:
            PetInfoStep()
        }
    }

    // MARK: - Footer Bar

    private var footerBar: some View {
        VStack(spacing: Layout.footerSpacing) {
            // Summary card (shows after first step)
            if coordinator.currentStep != .appSelection {
                SelectionSummaryCard()
            }

            // Navigation row: step indicator (centered) + next button (trailing)
            ZStack {
                // Add 1 to totalSteps to account for drop step (shown in DragPortalSheet)
                StepIndicator(
                    currentStep: coordinator.currentStep.rawValue,
                    totalSteps: coordinator.totalSteps + 1
                )

                HStack {
                    Spacer()
                    nextButton
                }
            }
        }
        .padding(.horizontal, Layout.footerPadding)
        .padding(.vertical, Layout.footerPadding)
        .background(footerBackground)
    }

    @ViewBuilder
    private var footerBackground: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .ignoresSafeArea(edges: .bottom)
    }

    private var nextButton: some View {
        Button {
            HapticType.impactMedium.trigger()
            if coordinator.currentStep.isLast {
                coordinator.proceedToDrop()
            } else {
                coordinator.nextStep()
            }
        } label: {
            Text(nextButtonTitle)
                .font(.body.weight(.semibold))
                .foregroundStyle(coordinator.canProceed ? .white : .secondary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(buttonBackground)
        }
        .disabled(!coordinator.canProceed)
    }

    private var nextButtonTitle: String {
        coordinator.currentStep.isLast ? "Drop Pet" : "Next"
    }

    @ViewBuilder
    private var buttonBackground: some View {
        let shape = Capsule()

        if coordinator.canProceed {
            shape.fill(Color.accentColor)
        } else {
            shape.fill(Color.secondary.opacity(0.2))
        }
    }

}

#if DEBUG
#Preview {
    CreatePetMultiStep()
        .environment(CreatePetCoordinator())
}
#endif
