import SwiftUI

/// Displays the cliff scene with rock, grass, and animated pet.
struct CliffView<Evolution: EvolutionType>: View {
    let screenHeight: CGFloat
    let evolution: Evolution
    let windLevel: WindLevel

    // Debug overrides (nil = use evolution's config)
    var debugWindConfig: WindConfig? = nil
    var windDirection: CGFloat = 1.0

    // MARK: - Computed Properties

    private var cliffHeight: CGFloat { screenHeight * 0.6 }
    private var petHeight: CGFloat { screenHeight * 0.15 }
    private var petOffset: CGFloat { -petHeight * 0.65 }

    private var activeWindConfig: WindConfig {
        debugWindConfig ?? evolution.windConfig(for: windLevel)
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .top) {
            // Rock with grass overlay (base layer)
            Image("rock")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: cliffHeight)
                .overlay(alignment: .top) {
                    Image("grass")
                        .resizable()
                        .scaledToFit()
                }

            // Pet with wind effect (top layer)
            Image(evolution.assetName)
                .resizable()
                .scaledToFit()
                .frame(height: petHeight)
                .windEffect(
                    intensity: activeWindConfig.intensity,
                    direction: windDirection,
                    bendCurve: activeWindConfig.bendCurve,
                    swayAmount: activeWindConfig.swayAmount,
                    rotationAmount: activeWindConfig.rotationAmount
                )
                .offset(y: petOffset)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    WindDebugView()
}
#endif
