import SwiftUI

struct EssenceCatalogGridItem: View {
    let entry: EssenceCatalogManager.CatalogEntry
    let essenceRecord: EssenceRecord?

    private var path: EvolutionPath { entry.evolutionPath }
    private var color: Color { .green }

    var body: some View {
        VStack(spacing: 10) {
            Text(path.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(entry.isUnlocked ? .primary : .secondary)
            essenceIcon
            evolutionCount
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .background { cardBackground }
        .overlay {
            if !entry.isUnlocked {
                lockOverlay
            }
        }
        .overlay(alignment: .topTrailing) {
            cornerBadge
                .padding(8)
        }
    }

    // MARK: - Subviews

    private var essenceIcon: some View {
        Image(entry.essence.assetName)
            .resizable()
            .scaledToFit()
            .frame(width: 64, height: 64)
            .opacity(entry.isUnlocked ? 1.0 : 0.5)
    }

    private var evolutionCount: some View {
        Text("\(path.maxPhases) evolutions")
            .font(.caption2)
            .foregroundStyle(entry.isUnlocked ? AnyShapeStyle(color) : AnyShapeStyle(.tertiary))
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
        Image(systemName: "lock.fill")
            .font(.system(size: 40))
            .foregroundStyle(.secondary.opacity(0.5))
            .allowsHitTesting(false)
    }

    // MARK: - Corner Badge

    @ViewBuilder
    private var cornerBadge: some View {
        if entry.isUnlocked {
            let reached = essenceRecord?.bestPhase ?? 0
            Text("\(reached)/\(path.maxPhases)")
                .font(.caption2.weight(.medium))
                .foregroundStyle(reached > 0 ? AnyShapeStyle(color) : AnyShapeStyle(.tertiary))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: Capsule())
        } else {
            HStack(spacing: 3) {
                Image("coin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                Text("\(entry.essence.price)")
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
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
