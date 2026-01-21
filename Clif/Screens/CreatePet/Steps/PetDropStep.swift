import FamilyControls
import SwiftUI

struct PetDropStep: View {
    @Environment(CreatePetCoordinator.self) private var coordinator
    @Environment(PetManager.self) private var petManager

    @State private var hapticController = DragHapticController()

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

                        if !coordinator.petPurpose.isEmpty {
                            Text(coordinator.petPurpose)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(Layout.innerPadding)
                    .background(cardBackground)

                    // Staging card with drag
                    PetStagingCard()
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
