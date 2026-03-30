import SwiftUI

/// Essence picker with catalog and staging area.
struct EssencePicker: View {
    @Environment(EssencePickerCoordinator.self) private var coordinator
    @Environment(EssenceCatalogManager.self) private var catalogManager
    @Environment(ArchivedPetManager.self) private var archivedPetManager
    @Environment(PetManager.self) private var petManager

    @State private var selectedEssence: Essence?
    @State private var essenceToUnlock: Essence?
    @State private var selectedEssenceRecord: EssenceRecord?
    @State private var hapticController = DragHapticController()

    private enum Layout {
        static let catalogSpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 16
    }

    private var selectedPath: EvolutionPath? {
        selectedEssence.map { EvolutionPath.path(for: $0) }
    }

    private var isSelectedLocked: Bool {
        guard let essence = selectedEssence else { return false }
        return !catalogManager.isUnlocked(essence)
    }

    private var sortedEssences: [Essence] {
        Essence.allCases.sorted { a, b in
            let aUnlocked = catalogManager.isUnlocked(a)
            let bUnlocked = catalogManager.isUnlocked(b)
            if aUnlocked != bUnlocked { return aUnlocked }
            return false
        }
    }

    var body: some View {
        VStack(spacing: Layout.sectionSpacing) {
            topSection

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Layout.catalogSpacing) {
                    ForEach(sortedEssences, id: \.self) { essence in
                        EssenceCatalogCard(
                            essence: essence,
                            isSelected: essence == selectedEssence,
                            isLocked: !catalogManager.isUnlocked(essence)
                        ) {
                            if essence == selectedEssence {
                                showEssenceSheet(essence)
                            } else {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedEssence = essence
                                }
                                coordinator.hasSelectedEssence = true
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
        .sheet(item: $essenceToUnlock) { essence in
            EssenceUnlockSheet(essence: essence)
        }
        .sheet(item: $selectedEssenceRecord) { record in
            EssenceDetailSheet(
                record: record,
                summaries: archivedPetManager.summaries
            )
        }
    }

    private var topSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Info section
                VStack(alignment: .leading, spacing: 8) {
                    if let path = selectedPath {
                        HStack(spacing: 0) {
                            Text(path.displayName)
                                .font(.headline)
                            Text(" · ")
                                .font(.headline)
                                .foregroundStyle(.tertiary)
                            Text("Drag to your pet")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Select an essence")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    if selectedEssence != nil {
                        Button {
                            if let essence = selectedEssence { showEssenceSheet(essence) }
                        } label: {
                            if isSelectedLocked {
                                HStack(spacing: 5) {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 12))
                                    Text("Unlock")
                                }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(.green, in: Capsule())
                            } else {
                                Text("Details")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.green)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(.green.opacity(0.12), in: Capsule())
                            }
                        }
                    } else {
                        Text("Drag to your pet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Staging area
                EssenceStagingCard(essence: selectedEssence, isLocked: isSelectedLocked, isDragging: coordinator.dragState.isDragging)
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .global)
                            .onChanged { value in
                                guard selectedEssence != nil else { return }
                                guard !isSelectedLocked else { return }
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
        .padding(.top, 4)
        .contentShape(Rectangle())
    }

    private func showEssenceSheet(_ essence: Essence) {
        if catalogManager.isUnlocked(essence) {
            let record = archivedPetManager
                .essenceRecords(currentPet: petManager.currentPet)
                .first { $0.essence == essence }
            selectedEssenceRecord = record ?? EssenceRecord(
                id: essence.name,
                essence: essence,
                bestPhase: nil,
                petCount: 0
            )
        } else {
            essenceToUnlock = essence
        }
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
    var isLocked: Bool = false
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
                            .opacity(isLocked ? 0.35 : 1.0)
                            .overlay {
                                if isLocked {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(.secondary.opacity(0.7))
                                }
                            }
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
        .animation(nil, value: isDragging)
    }
}

// MARK: - Catalog Card (Tappable)

private struct EssenceCatalogCard: View {
    let essence: Essence
    let isSelected: Bool
    let isLocked: Bool
    let onTap: () -> Void

    private var path: EvolutionPath {
        EvolutionPath.path(for: essence)
    }

    var body: some View {
        Image(essence.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: CardStyle.imageSize, height: CardStyle.imageSize)
            .opacity(isLocked ? 0.35 : 1.0)
            .overlay {
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.secondary.opacity(0.7))
                        .allowsHitTesting(false)
                }
            }
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
                        ? .regular.tint(.green.opacity(CardStyle.glassTintOpacity))
                        : .regular,
                    in: shape
                )
                .overlay {
                    shape.stroke(
                        isSelected ? .green.opacity(CardStyle.subtleStrokeOpacity) : Color.clear,
                        lineWidth: 1
                    )
                }
        } else {
            shape
                .fill(isSelected ? .green.opacity(CardStyle.fillOpacity) : Color.clear)
                .background(.ultraThinMaterial, in: shape)
                .overlay {
                    shape.stroke(
                        isSelected ? .green.opacity(CardStyle.subtleStrokeOpacity) : Color.clear,
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
#Preview("Default (only plant unlocked)") {
    EssencePicker()
        .environment(EssencePickerCoordinator())
        .environment(EssenceCatalogManager.mock())
        .environment(ArchivedPetManager.mock())
        .environment(PetManager.mock())
}

#Preview("All unlocked") {
    EssencePicker()
        .environment(EssencePickerCoordinator())
        .environment(EssenceCatalogManager.mock(allUnlocked: true))
        .environment(ArchivedPetManager.mock())
        .environment(PetManager.mock())
}
#endif
