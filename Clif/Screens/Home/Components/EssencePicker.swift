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
                            coordinator.hasSelectedEssence = true
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
                EssenceStagingCard(essence: selectedEssence, isDragging: coordinator.dragState.isDragging)
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

        // Use essence preview position (with offset), not finger position
        let essencePosition = DragPreviewOffset.adjustedPosition(from: location)
        guard let petDropFrame = coordinator.petDropFrame,
              petDropFrame.contains(essencePosition) else { return }

        coordinator.handleDrop(essence)
        coordinator.hasSelectedEssence = false
        selectedEssence = nil
        HapticType.notificationSuccess.trigger()
    }

    private func updateDragHaptics(at location: CGPoint) {
        let previewPosition = DragPreviewOffset.adjustedPosition(from: location)
        hapticController.updateProximityIntensity(at: previewPosition, targetFrame: coordinator.petDropFrame)
    }
}

// MARK: - Card Style Constants

private enum CardStyle {
    static let imageSize: CGFloat = 60
    static let padding: CGFloat = 12
    static let cornerRadius: CGFloat = 32

    static let glassTintOpacity: CGFloat = 0.15
    static let fillOpacity: CGFloat = 0.1
    static let strokeOpacity: CGFloat = 0.3
    static let subtleStrokeOpacity: CGFloat = 0.2
}

// MARK: - Staging Card

private struct EssenceStagingCard: View {
    let essence: Essence?
    var isDragging: Bool = false

    var body: some View {
        ZStack {
            if isDragging {
                RoundedRectangle(cornerRadius: CardStyle.cornerRadius)
                    .strokeBorder(
                        Color.secondary.opacity(0.2),
                        style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                    )
                    .frame(
                        width: CardStyle.imageSize + CardStyle.padding * 2,
                        height: CardStyle.imageSize + CardStyle.padding * 2
                    )
            } else {
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
                .glassBackground(cornerRadius: CardStyle.cornerRadius)
            }
        }
        .transaction { $0.animation = nil }
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
            .onTapGesture {
                HapticType.impactLight.trigger()
                onTap()
            }
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
        static let shadowOpacity: CGFloat = 0.2
        static let shadowRadius: CGFloat = 10
        static let shadowY: CGFloat = 4
    }

    var body: some View {
        Image(essence.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: Layout.imageSize, height: Layout.imageSize)
            .shadow(color: .black.opacity(Layout.shadowOpacity), radius: Layout.shadowRadius, x: 0, y: Layout.shadowY)
    }
}

#if DEBUG
#Preview {
    EssencePicker()
        .environment(EssencePickerCoordinator())
}
#endif
