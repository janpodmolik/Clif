import SwiftUI
import Combine

/// State for drag operation, shared with parent for overlay rendering
struct EssenceDragState {
    var isDragging: Bool = false
    var dragLocation: CGPoint = .zero
    var draggedEssence: Essence?
}

/// Essence picker with catalog and staging area.
struct EssencePicker: View {
    @Environment(EssencePickerCoordinator.self) private var coordinator

    @State private var selectedEssence: Essence?
    @StateObject private var hapticController = DragHapticController()

    private let dismissThreshold: CGFloat = 100

    private var selectedPath: EvolutionPath? {
        selectedEssence.map { EvolutionPath.path(for: $0) }
    }

    private var dismissDragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = max(0, value.translation.height)
                coordinator.dismissDragOffset = translation
            }
            .onEnded { value in
                let velocity = value.predictedEndTranslation.height - value.translation.height
                let shouldDismiss = value.translation.height > dismissThreshold || velocity > 300
                if shouldDismiss {
                    coordinator.dismiss()
                } else {
                    coordinator.dismissDragOffset = 0
                }
            }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Top section with dismiss drag support
            topSection
                .gesture(dismissDragGesture)

            // Catalog - NO dismiss drag (has scroll gesture)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
            hapticController.updateIntensity(0.2)
            return
        }

        let center = CGPoint(x: petDropFrame.midX, y: petDropFrame.midY)
        let distance = hypot(location.x - center.x, location.y - center.y)
        let maxDistance = max(petDropFrame.width, petDropFrame.height) * 2.4
        let normalized = max(0, min(1, 1 - (distance / maxDistance)))
        let intensity = 0.15 + (normalized * 0.85)
        hapticController.updateIntensity(intensity)
    }
}

// MARK: - Staging Card

private struct EssenceStagingCard: View {
    let essence: Essence?

    private var path: EvolutionPath? {
        essence.map { EvolutionPath.path(for: $0) }
    }

    var body: some View {
        Group {
            if let essence {
                Image(essence.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
            } else {
                Image(systemName: "sparkles")
                    .font(.title)
                    .foregroundStyle(.tertiary)
                    .frame(width: 60, height: 60)
            }
        }
        .padding(12)
        .background(cardBackground)
    }

    @ViewBuilder
    private var cardBackground: some View {
        let themeColor = path?.themeColor ?? .secondary

        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    essence != nil
                        ? .regular.tint(themeColor.opacity(0.15))
                        : .regular,
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeColor.opacity(0.3), lineWidth: 2)
                }
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(essence != nil ? themeColor.opacity(0.1) : Color.clear)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeColor.opacity(0.3), lineWidth: 2)
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
            .frame(width: 60, height: 60)
            .padding(12)
            .background(cardBackground)
            .onTapGesture(perform: onTap)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    isSelected
                        ? .regular.tint(path.themeColor.opacity(0.15))
                        : .regular,
                    in: RoundedRectangle(cornerRadius: 16)
                )
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? path.themeColor.opacity(0.1) : Color.clear)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? path.themeColor.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                }
        }
    }
}

struct EssenceDragPreview: View {
    let essence: Essence

    private var path: EvolutionPath {
        EvolutionPath.path(for: essence)
    }

    var body: some View {
        Image(essence.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: 56, height: 56)
            .padding(10)
            .background(previewBackground)
            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 6)
    }

    @ViewBuilder
    private var previewBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    .regular.tint(path.themeColor.opacity(0.15)),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(path.themeColor.opacity(0.25), lineWidth: 1)
                }
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(path.themeColor.opacity(0.12))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(path.themeColor.opacity(0.25), lineWidth: 1)
                }
        }
    }
}

private final class DragHapticController: ObservableObject {
    private var timer: Timer?
    private var generator = UIImpactFeedbackGenerator(style: .light)
    private var intensity: CGFloat = 0.2

    func startDragging() {
        intensity = 0.2
        timer?.invalidate()
        generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()

        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func updateIntensity(_ intensity: CGFloat) {
        self.intensity = max(0, min(1, intensity))
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
