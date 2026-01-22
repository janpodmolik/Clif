import FamilyControls
import SwiftUI

struct PetDropStep: View {
    @Environment(CreatePetCoordinator.self) private var coordinator
    @Environment(PetManager.self) private var petManager

    @State private var hapticController = DragHapticController()
    @State private var stagingCardFrame: CGRect = .zero

    private enum Layout {
        static let outerPadding: CGFloat = 16
        static let cardSpacing: CGFloat = 12
        static let innerPadding: CGFloat = 16
        static let outerCornerRadius: CGFloat = 24
        static var innerCornerRadius: CGFloat {
            DeviceMetrics.concentricCornerRadius(inset: outerPadding + innerPadding)
        }
    }

    private enum Haptics {
        static let maxDistanceMultiplier: CGFloat = 2.4
        static let baseIntensity: CGFloat = 0.15
        static let intensityRange: CGFloat = 0.85
        static let fallbackIntensity: CGFloat = 0.2
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header with back/cancel buttons
            HStack {
                CircleButton(icon: "chevron.left") {
                    coordinator.backFromDrop()
                }

                Spacer()

                VStack(spacing: 2) {
                    Text("Review & Drop")
                        .font(.headline)
                    Text("Drag the blob to the island")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                CircleButton(icon: "xmark") {
                    coordinator.dismiss()
                }
            }
            .padding(.horizontal, Layout.outerPadding)
            .padding(.top, 12)

            // Content area
            VStack(spacing: Layout.cardSpacing) {
                // Row 1: Pet info + staging card
                HStack(spacing: Layout.cardSpacing) {
                    // Pet name and purpose
                    VStack(alignment: .leading, spacing: 4) {
                        Text(coordinator.petName.isEmpty ? "Your Pet" : coordinator.petName)
                            .font(.title3.weight(.semibold))

                        Text(coordinator.petPurpose.isEmpty ? "No special purpose" : coordinator.petPurpose)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(Layout.innerPadding)
                    .background(cardBackground)

                    // Staging card with drag
                    PetStagingCard(isDragging: coordinator.dragState.isDragging || coordinator.dragState.isReturning)
                        .background {
                            GeometryReader { proxy in
                                Color.clear
                                    .onAppear {
                                        stagingCardFrame = proxy.frame(in: .global)
                                    }
                                    .onChange(of: proxy.frame(in: .global)) { _, newFrame in
                                        stagingCardFrame = newFrame
                                    }
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                                .onChanged { value in
                                    if !coordinator.dragState.isDragging {
                                        startDragging(at: value.startLocation)
                                    }
                                    coordinator.dragState.dragLocation = value.location
                                    coordinator.dragState.dragVelocity = value.velocity
                                    updateSnapState(at: value.location)
                                    updateDragHaptics(at: value.location)
                                }
                                .onEnded { value in
                                    handleDragEnded(at: value.location)
                                }
                        )
                }
                .fixedSize(horizontal: false, vertical: true)

                Divider()
                    .padding(.horizontal, 8)

                // Row 2: Limits + Mode cards
                HStack(spacing: Layout.cardSpacing) {
                    // Limits card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Limits")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        LimitedSourcesPreview(
                            applicationTokens: coordinator.selectedApps.applicationTokens,
                            categoryTokens: coordinator.selectedApps.categoryTokens,
                            webDomainTokens: coordinator.selectedApps.webDomainTokens
                        )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(Layout.innerPadding)
                    .background(cardBackground)

                    // Mode card
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(coordinator.modeInfo.shortName) Mode")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)

                        Text(modeDisplayText)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(Layout.innerPadding)
                    .background(cardBackground)
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: coordinator.modeInfo.iconName)
                            .font(.subheadline)
                            .foregroundStyle(coordinator.modeInfo.themeColor)
                            .padding(Layout.innerPadding)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(Layout.outerPadding)
        }
        .padding(.top)
        .onDisappear {
            hapticController.stop()
        }
    }

    // MARK: - Card Background

    @ViewBuilder
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: Layout.innerCornerRadius)
            .fill(.ultraThinMaterial)
    }

    private var modeDisplayText: String {
        if coordinator.selectedMode == .daily {
            return MinutesFormatter.rate(coordinator.dailyLimitMinutes)
        } else {
            return coordinator.dynamicConfig.displayName
        }
    }

    // MARK: - Drag Handling

    private func startDragging(at location: CGPoint) {
        coordinator.dragState.isDragging = true
        coordinator.dragState.startLocation = CGPoint(
            x: stagingCardFrame.midX,
            y: stagingCardFrame.midY
        )
        hapticController.startDragging()
        HapticType.impactLight.trigger()
    }

    private func handleDragEnded(at location: CGPoint) {
        hapticController.stop()

        // Use blob position (with offset), not finger position
        let blobPosition = CGPoint(
            x: location.x - 20,
            y: location.y - 50
        )

        guard let petDropFrame = coordinator.petDropFrame,
              petDropFrame.contains(blobPosition) else {
            // Failed drop - return pet to staging card
            triggerReturnAnimation()
            return
        }

        // Successful drop
        coordinator.dragState.isDragging = false
        coordinator.handleBlobDrop(petManager: petManager)
        HapticType.notificationSuccess.trigger()
    }

    private func triggerReturnAnimation() {
        // Start return animation
        coordinator.dragState.isReturning = true
        coordinator.dragState.isDragging = false

        // Animate back to start position
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            coordinator.dragState.dragLocation = coordinator.dragState.startLocation
            coordinator.dragState.dragVelocity = .zero
        }

        // Reset state after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            coordinator.dragState.isReturning = false
        }

        HapticType.notificationError.trigger()
    }

    private func updateSnapState(at location: CGPoint) {
        guard let petDropFrame = coordinator.petDropFrame else {
            coordinator.dragState.isSnapped = false
            return
        }

        // Use blob position (with offset), not finger position
        let blobPosition = CGPoint(
            x: location.x - 20,
            y: location.y - 50
        )
        let isSnapped = petDropFrame.contains(blobPosition)
        if isSnapped != coordinator.dragState.isSnapped {
            coordinator.dragState.isSnapped = isSnapped
            if isSnapped {
                coordinator.dragState.snapTargetCenter = CGPoint(
                    x: petDropFrame.midX,
                    y: petDropFrame.midY
                )
                HapticType.impactMedium.trigger()
            }
        }
    }

    private func updateDragHaptics(at location: CGPoint) {
        guard let petDropFrame = coordinator.petDropFrame else {
            hapticController.updateIntensity(Haptics.fallbackIntensity)
            return
        }

        let center = CGPoint(x: petDropFrame.midX, y: petDropFrame.midY)
        let distance = hypot(location.x - center.x, location.y - center.y)
        let maxDistance = max(petDropFrame.width, petDropFrame.height) * Haptics.maxDistanceMultiplier
        let normalized = max(0, min(1, 1 - (distance / maxDistance)))
        let intensity = Haptics.baseIntensity + (normalized * Haptics.intensityRange)
        hapticController.updateIntensity(intensity)
    }
}

// MARK: - Drag Haptic Controller

private final class DragHapticController {
    private var timer: Timer?
    private var generator = UIImpactFeedbackGenerator(style: .light)
    private var intensity: CGFloat = 0.2

    private static let tickInterval: TimeInterval = 0.15
    private static let defaultIntensity: CGFloat = 0.2

    func startDragging() {
        intensity = Self.defaultIntensity
        timer?.invalidate()
        generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()

        timer = Timer.scheduledTimer(withTimeInterval: Self.tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func updateIntensity(_ newIntensity: CGFloat) {
        intensity = max(0, min(1, newIntensity))
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        generator.prepare()
        generator.impactOccurred(intensity: intensity)
    }

    deinit {
        stop()
    }
}

#if DEBUG
#Preview {
    PetDropStep()
        .environment(CreatePetCoordinator())
        .environment(PetManager.mock())
}
#endif
