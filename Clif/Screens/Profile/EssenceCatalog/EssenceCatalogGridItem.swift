import SwiftUI

struct EssenceCatalogGridItem: View {
    let entry: EssenceCatalogManager.CatalogEntry
    let essenceRecord: EssenceRecord?

    private var path: EvolutionPath { entry.evolutionPath }
    private var color: Color { path.themeColor }

    var body: some View {
        VStack(spacing: 10) {
            essenceIcon
            pathInfo
            evolutionCount
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background { cardBackground }
        .overlay {
            if !entry.isUnlocked {
                lockOverlay
            }
        }
    }

    // MARK: - Subviews

    private var essenceIcon: some View {
        Image(entry.essence.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: 64, height: 64)
    }

    private var pathInfo: some View {
        VStack(spacing: 2) {
            Text(path.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(entry.isUnlocked ? .primary : .secondary)

            Text(entry.essence.rarity.displayName)
                .font(.caption2)
                .foregroundStyle(entry.essence.rarity.color)

            if let record = essenceRecord, record.petCount > 0 {
                Text(record.petCount == 1 ? "1 pet" : "\(record.petCount) pets")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var evolutionCount: some View {
        let maxPhases = path.maxPhases
        let reached = essenceRecord?.bestPhase ?? 0

        return Text("\(reached)/\(maxPhases) evolucí")
            .font(.caption2)
            .foregroundStyle(reached > 0 ? AnyShapeStyle(color) : AnyShapeStyle(.tertiary))
            .opacity(entry.isUnlocked ? 1.0 : 0.5)
    }

    // MARK: - Background

    @ViewBuilder
    private var cardBackground: some View {
        let tintOpacity: Double = entry.isUnlocked ? 0.12 : 0.05
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    .regular.tint(color.opacity(tintOpacity)),
                    in: RoundedRectangle(cornerRadius: 16)
                )
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(entry.isUnlocked ? 0.08 : 0.03))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                }
        }
    }

    // MARK: - Lock Overlay

    private var lockOverlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.ultraThinMaterial.opacity(0.3))
            .overlay {
                Image(systemName: "lock.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
    }
}

// MARK: - Preview

#Preview {
    LazyVGrid(
        columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
        spacing: 12
    ) {
        EssenceCatalogGridItem(
            entry: .init(essence: .plant, isUnlocked: true),
            essenceRecord: EssenceRecord(id: "plant", essence: .plant, bestPhase: 3, petCount: 2)
        )

        EssenceCatalogGridItem(
            entry: .init(essence: .plant, isUnlocked: false),
            essenceRecord: nil
        )
    }
    .padding()
}
