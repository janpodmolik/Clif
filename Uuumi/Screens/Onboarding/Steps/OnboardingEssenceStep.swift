import SwiftUI

struct OnboardingEssenceStep: View {
    let skipAnimation: Bool
    var onContinue: () -> Void
    @Binding var windProgress: CGFloat
    @Binding var eyesOverride: String?
    @Binding var showDropZone: Bool
    @Binding var isOnTarget: Bool
    @Binding var reactionTrigger: UUID?
    var petDropFrame: CGRect?

    // MARK: - Narrative State

    @State private var narrativeBeat = 0
    @State private var showSecondLine = false
    @State private var textCompleted = false

    // MARK: - Drag State

    @State private var showStagingArea = false
    @State private var isDragging = false
    @State private var dragLocation: CGPoint = .zero
    @State private var hapticController = DragHapticController()
    @State private var overlayOrigin: CGPoint = .zero

    // MARK: - Completion

    @State private var hasDropped = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 0) {
            narrative
                .padding(.horizontal, 32)
                .padding(.top, 60)

            Spacer()

            if showButton {
                continueButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else if showStagingArea && !hasDropped {
                stagingArea
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .overlay {
            GeometryReader { proxy in
                if isDragging {
                    let globalPosition = DragPreviewOffset.adjustedPosition(from: dragLocation)
                    let localPosition = CGPoint(
                        x: globalPosition.x - overlayOrigin.x,
                        y: globalPosition.y - overlayOrigin.y
                    )
                    Image(systemName: "sparkles")
                        .font(.largeTitle)
                        .foregroundStyle(.primary)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                        .position(localPosition)
                        .allowsHitTesting(false)
                }
            }
            .onGeometryChange(for: CGPoint.self) { proxy in
                proxy.frame(in: .global).origin
            } action: { origin in
                overlayOrigin = origin
            }
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
        .animation(.easeOut(duration: 0.3), value: showStagingArea)
        .animation(.easeOut(duration: 0.3), value: showButton)
        .animation(.easeOut(duration: 0.2), value: hasDropped)
        .onAppear { handleAppear() }
        .onDisappear { handleDisappear() }
    }

    // MARK: - Narrative

    private var narrative: some View {
        VStack(spacing: 12) {
            if skipAnimation {
                Text("After your first day, you can give your Uuumi an essence.")
                Text("Let's practice it now.")
                    .font(AppFont.quicksand(.subheadline, weight: .medium))
                    .foregroundStyle(.secondary)
            } else {
                let skipped = narrativeBeat >= 1

                TypewriterText(
                    text: "After your first day, you can give your Uuumi an essence.",
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
                    text: "Let's practice it now.",
                    active: showSecondLine,
                    skipRequested: narrativeBeat >= 2,
                    onCompleted: {
                        textCompleted = true
                        Task {
                            try? await Task.sleep(for: .seconds(0.3))
                            withAnimation {
                                showStagingArea = true
                                showDropZone = true
                            }
                        }
                    }
                )
                .font(AppFont.quicksand(.subheadline, weight: .medium))
                .foregroundStyle(.secondary)
                .opacity(showSecondLine ? 1 : 0)
            }
        }
        .font(AppFont.quicksand(.title2, weight: .semiBold))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.center)
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

    // MARK: - Staging Area

    private var stagingArea: some View {
        VStack(spacing: 12) {
            Text("Drag essence to Uuumi")
                .font(AppFont.quicksand(.caption, weight: .medium))
                .foregroundStyle(.secondary)

            essenceCard
        }
    }

    private var essenceCard: some View {
        Image(systemName: "sparkles")
            .font(.largeTitle)
            .foregroundStyle(.primary)
            .frame(width: 80, height: 80)
            .glassBackground(cornerRadius: 24)
            .opacity(isDragging ? 0.3 : 1)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            hapticController.startDragging()
                            HapticType.impactLight.trigger()
                        }
                        dragLocation = value.location
                        updateDragState(at: value.location)
                    }
                    .onEnded { value in
                        handleDragEnded(at: value.location)
                    }
            )
    }

    // MARK: - Drag Logic

    private static let dropTargetExpansion: CGFloat = 40

    private var expandedPetFrame: CGRect? {
        petDropFrame?.insetBy(
            dx: -Self.dropTargetExpansion,
            dy: -Self.dropTargetExpansion
        )
    }

    private func updateDragState(at location: CGPoint) {
        let previewPosition = DragPreviewOffset.adjustedPosition(from: location)
        hapticController.updateProximityIntensity(at: previewPosition, targetFrame: expandedPetFrame)

        let onTarget = expandedPetFrame?.contains(previewPosition) ?? false
        if onTarget != isOnTarget {
            isOnTarget = onTarget
        }
    }

    private func handleDragEnded(at location: CGPoint) {
        defer {
            isDragging = false
            isOnTarget = false
            hapticController.stop()
        }

        let previewPosition = DragPreviewOffset.adjustedPosition(from: location)
        guard let frame = expandedPetFrame, frame.contains(previewPosition) else { return }

        // Successful drop
        HapticType.notificationSuccess.trigger()
        hasDropped = true
        showDropZone = false

        // Trigger bounce reaction on pet
        reactionTrigger = UUID()

        // Show continue button after a brief pause
        Task {
            try? await Task.sleep(for: .seconds(0.6))
            withAnimation { showButton = true }
        }
    }

    // MARK: - Lifecycle

    private func handleAppear() {
        windProgress = 0
        eyesOverride = "happy"

        if skipAnimation {
            showSecondLine = true
            textCompleted = true
            // If already completed (navigated back), show staging area
            if !hasDropped {
                showStagingArea = true
                showDropZone = true
            }
        }
    }

    private func handleDisappear() {
        showDropZone = false
        isOnTarget = false
        hapticController.stop()
    }
}

#if DEBUG
#Preview {
    OnboardingStepPreview(showBlob: true, showWind: false) { _, windProgress, eyesOverride in
        OnboardingEssenceStep(
            skipAnimation: false,
            onContinue: {},
            windProgress: windProgress,
            eyesOverride: eyesOverride,
            showDropZone: .constant(false),
            isOnTarget: .constant(false),
            reactionTrigger: .constant(nil)
        )
    }
}
#endif
