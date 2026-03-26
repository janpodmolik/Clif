import SwiftUI

/// Card shown in EvolutionCarousel when the pet has an essence the app doesn't recognize.
/// Displays the unknown-essence asset with the essence ID and evolution count.
struct UnknownEssenceCard: View {
    let essenceId: Int
    let evolutionCount: Int
    let currentPhase: Int

    var body: some View {
        VStack(spacing: 12) {
            Image("unknown-essence")
                .resizable()
                .scaledToFit()
                .frame(height: 140)

            Text(displayName)
                .font(.subheadline.weight(.semibold))

            Text("Unknown essence")
                .font(.caption2)
                .foregroundStyle(.orange)

            statusLabel
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(cardBackground)
    }

    private var displayName: String {
        "Essence #\(essenceId)"
    }

    @ViewBuilder
    private var statusLabel: some View {
        if evolutionCount > 0 {
            Text("Phase \(currentPhase) · \(evolutionCount) \(evolutionCount == 1 ? "evolution" : "evolutions")")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Text("Phase \(currentPhase)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var cardBackground: some View {
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(
                    .regular.tint(Color.orange.opacity(0.08)),
                    in: RoundedRectangle(cornerRadius: 20)
                )
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.orange.opacity(0.08))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                }
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 20) {
        UnknownEssenceCard(
            essenceId: 42,
            evolutionCount: 2,
            currentPhase: 3
        )
        .frame(width: 230, height: 240)

        UnknownEssenceCard(
            essenceId: 99,
            evolutionCount: 0,
            currentPhase: 1
        )
        .frame(width: 230, height: 240)
    }
    .padding()
}
#endif
