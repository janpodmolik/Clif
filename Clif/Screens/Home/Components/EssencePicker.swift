import SwiftUI

/// Essence picker with catalog and staging area.
struct EssencePicker: View {
    @Environment(EssencePickerCoordinator.self) private var coordinator

    @State private var selectedEssence: Essence?
    @State private var hapticController = DragHapticController()

    private enum Layout {
        static let catalogSpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 16
    }

    private enum Haptics {
        static let maxDistanceMultiplier: CGFloat = 2.4
        static let baseIntensity: CGFloat = 0.15
        static let intensityRange: CGFloat = 0.85
        static let fallbackIntensity: CGFloat = 0.2
    }

    private var selectedPath: EvolutionPath? {
        selectedEssence.map { EvolutionPath.path(for: $0) }
    }

    var body: some View {
        VStack(spacing: Layout.sectionSpacing) {
            topSection

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Layout.catalogSpacing) {
                    ForEach(Essence.allCases, id: \.self) { essence in
                        EssenceCatalogCard(
                            essence: essence,
                            isSelected: essence == selectedEssence
                        ) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedEssence = essence
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.bottom)
        .onDisappear {
            hapticController.stop()
        }
    }

    @ViewBuilder
    private var topSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Close button
                Button {
                    coordinator.dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                // Info section
                VStack(alignment: .leading, spacing: 4) {
                    if let path = selectedPath {
                        Text(path.displayName)
                            .font(.headline)
                    } else {
                        Text("Select an essence")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    Text("Drag to your pet")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Staging area - instant drag
                EssenceStagingCard(essence: selectedEssence)
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .global)
                            .onChanged { value in
                                guard selectedEssence != nil else { return }
                                if !coordinator.dragState.isDragging {
                                    startDragging()
                                }
                                coordinator.dragState.dragLocation = value.location
                                updateDragHaptics(at: value.location)
                            }
                            .onEnded { value in
                                guard coordinator.dragState.isDragging else { return }
                                handleDragEnded(at: value.location)
                            }
                    )
            }
            .padding(.horizontal)

            Divider()
                .padding(.horizontal)
        }
        .contentShape(Rectangle())
    }

    private func startDragging() {
        guard let essence = selectedEssence else { return }
        coordinator.dragState.isDragging = true
        coordinator.dragState.draggedEssence = essence
        hapticController.startDragging()
        HapticType.impactLight.trigger()
    }

    private func handleDragEnded(at location: CGPoint) {
        defer {
            coordinator.dragState.isDragging = false
            coordinator.dragState.draggedEssence = nil
            hapticController.stop()
        }

        guard let essence = selectedEssence else { return }
        guard let petDropFrame = coordinator.petDropFrame,
              petDropFrame.contains(location) else { return }

        coordinator.handleDrop(essence)
        selectedEssence = nil
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

// MARK: - Card Style Constants

private enum CardStyle {
    static let imageSize: CGFloat = 60
    static let padding: CGFloat = 12
    static let cornerRadius: CGFloat = 16

    static let glassTintOpacity: CGFloat = 0.15
    static let fillOpacity: CGFloat = 0.1
    static let strokeOpacity: CGFloat = 0.3
    static let subtleStrokeOpacity: CGFloat = 0.2
}

// MARK: - Staging Card

private struct EssenceStagingCard: View {
    let essence: Essence?

    private var path: EvolutionPath? {
        essence.map { EvolutionPath.path(for: $0) }
    }

    private var themeColor: Color {
        path?.themeColor ?? .secondary
    }

    var body: some View {
        Group {
            if let essence {
                Image(essence.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: CardStyle.imageSize, height: CardStyle.imageSize)
            } else {
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(.tertiary)
                    .frame(width: CardStyle.imageSize, height: CardStyle.imageSize)
            }
        }
        .padding(CardStyle.padding)
        .background(cardBackground)
    }

    @ViewBuilder
    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: CardStyle.cornerRadius)

        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    essence != nil
                        ? .regular.tint(themeColor.opacity(CardStyle.glassTintOpacity))
                        : .regular,
                    in: shape
                )
                .overlay {
                    shape.stroke(themeColor.opacity(CardStyle.strokeOpacity), lineWidth: 2)
                }
        } else {
            shape
                .fill(essence != nil ? themeColor.opacity(CardStyle.fillOpacity) : Color.clear)
                .background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.stroke(themeColor.opacity(CardStyle.strokeOpacity), lineWidth: 2)
                }
        }
    }
}

// MARK: - Catalog Card (Tappable)

private struct EssenceCatalogCard: View {
    let essence: Essence
    let isSelected: Bool
    let onTap: () -> Void

    private var path: EvolutionPath {
        EvolutionPath.path(for: essence)
    }

    var body: some View {
        Image(essence.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: CardStyle.imageSize, height: CardStyle.imageSize)
            .padding(CardStyle.padding)
            .background(cardBackground)
            .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private var cardBackground: some View {
        let shape = RoundedRectangle(cornerRadius: CardStyle.cornerRadius)

        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    isSelected
                        ? .regular.tint(path.themeColor.opacity(CardStyle.glassTintOpacity))
                        : .regular,
                    in: shape
                )
                .overlay {
                    shape.stroke(
                        isSelected ? path.themeColor.opacity(CardStyle.subtleStrokeOpacity) : Color.clear,
                        lineWidth: 1
                    )
                }
        } else {
            shape
                .fill(isSelected ? path.themeColor.opacity(CardStyle.fillOpacity) : Color.clear)
                .background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.stroke(
                        isSelected ? path.themeColor.opacity(CardStyle.subtleStrokeOpacity) : Color.clear,
                        lineWidth: 1
                    )
                }
        }
    }
}

struct EssenceDragPreview: View {
    let essence: Essence

    private enum Layout {
        static let imageSize: CGFloat = 56
        static let padding: CGFloat = 10
        static let shadowOpacity: CGFloat = 0.18
        static let shadowRadius: CGFloat = 8
        static let shadowY: CGFloat = 6
    }

    private var path: EvolutionPath {
        EvolutionPath.path(for: essence)
    }

    var body: some View {
        Image(essence.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: Layout.imageSize, height: Layout.imageSize)
            .padding(Layout.padding)
            .background(previewBackground)
            .shadow(color: .black.opacity(Layout.shadowOpacity), radius: Layout.shadowRadius, x: 0, y: Layout.shadowY)
    }

    @ViewBuilder
    private var previewBackground: some View {
        let shape = RoundedRectangle(cornerRadius: CardStyle.cornerRadius)

        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    .regular.tint(path.themeColor.opacity(CardStyle.glassTintOpacity)),
                    in: shape
                )
                .overlay {
                    shape.stroke(path.themeColor.opacity(CardStyle.subtleStrokeOpacity), lineWidth: 1)
                }
        } else {
            shape
                .fill(path.themeColor.opacity(CardStyle.fillOpacity))
                .background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.stroke(path.themeColor.opacity(CardStyle.subtleStrokeOpacity), lineWidth: 1)
                }
        }
    }
}

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
    EssencePicker()
        .environment(EssencePickerCoordinator())
}
#endif
