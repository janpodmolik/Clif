import FamilyControls
import SwiftUI

struct PetDropStep: View {
    @Environment(CreatePetCoordinator.self) private var coordinator
    @Environment(PetManager.self) private var petManager

    @State private var hapticController = DragHapticController()

    private enum Layout {
        static let cardCornerRadius: CGFloat = 20
        static let cardPadding: CGFloat = 16
        static let rowSpacing: CGFloat = 12
    }

    private enum Haptics {
        static let maxDistanceMultiplier: CGFloat = 2.4
        static let baseIntensity: CGFloat = 0.15
        static let intensityRange: CGFloat = 0.85
        static let fallbackIntensity: CGFloat = 0.2
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Review & Drop")
                .font(.title3.weight(.semibold))

            Text("Drag the blob to the island")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Main card: overview + blob
            HStack(spacing: Layout.cardPadding) {
                // Left: Overview rows
                VStack(alignment: .leading, spacing: Layout.rowSpacing) {
                    overviewRow(icon: "app.badge.fill", label: "Apps") {
                        LimitedSourcesPreview(
                            applicationTokens: coordinator.selectedApps.applicationTokens,
                            categoryTokens: coordinator.selectedApps.categoryTokens,
                            webDomainTokens: coordinator.selectedApps.webDomainTokens
                        )
                    }

                    overviewRow(
                        icon: coordinator.selectedMode.iconName,
                        label: coordinator.selectedMode.shortName
                    ) {
                        Text(modeDisplayText)
                            .font(.subheadline.weight(.medium))
                    }

                    if !coordinator.petName.isEmpty {
                        overviewRow(icon: "leaf.fill", label: "Name") {
                            Text(coordinator.petName)
                                .font(.subheadline.weight(.medium))
                        }
                    }
                }

                Spacer()

                // Right: Blob
                BlobStagingCard()
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .global)
                            .onChanged { value in
                                if !coordinator.dragState.isDragging {
                                    startDragging()
                                }
                                coordinator.dragState.dragLocation = value.location
                                updateDragHaptics(at: value.location)
                            }
                            .onEnded { value in
                                handleDragEnded(at: value.location)
                            }
                    )
            }
            .padding(Layout.cardPadding)
            .glassBackground(cornerRadius: Layout.cardCornerRadius)
            .padding(.horizontal)
        }
        .padding(.top)
        .onDisappear {
            hapticController.stop()
        }
    }

    // MARK: - Overview Rows

    private func overviewRow<Content: View>(
        icon: String,
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .foregroundStyle(.tertiary)

            content()
        }
    }

    private var modeDisplayText: String {
        if coordinator.selectedMode == .daily {
            return MinutesFormatter.rate(coordinator.dailyLimitMinutes)
        } else {
            return coordinator.dynamicConfig.displayName
        }
    }

    // MARK: - Drag Handling

    private func startDragging() {
        coordinator.dragState.isDragging = true
        hapticController.startDragging()
        HapticType.impactLight.trigger()
    }

    private func handleDragEnded(at location: CGPoint) {
        defer {
            coordinator.dragState.isDragging = false
            hapticController.stop()
        }

        guard let petDropFrame = coordinator.petDropFrame,
              petDropFrame.contains(location) else { return }

        coordinator.handleBlobDrop(petManager: petManager)
        HapticType.notificationSuccess.trigger()
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
