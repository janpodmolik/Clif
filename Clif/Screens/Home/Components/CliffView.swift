import SwiftUI

/// Displays the cliff scene with rock, grass, and animated pet.
///
/// The pet sits on top of the cliff and responds to wind animation.
/// Accepts custom wind parameters for DEBUG testing via WindDebugView.
struct CliffView: View {
    let screenHeight: CGFloat

    // Wind effect parameters
    var windIntensity: CGFloat = 0.5
    var windDirection: CGFloat = 1.0
    var petSkin: Int = 1
    var bendCurve: CGFloat? = nil
    var swayAmount: CGFloat = 0.0
    var rotationAmount: CGFloat = 0.5

    // MARK: - Computed Properties

    private var cliffHeight: CGFloat { screenHeight * 0.6 }
    private var petHeight: CGFloat { screenHeight * 0.15 }
    private var petOffset: CGFloat { -petHeight * 0.65 }

    /// Default bend curve values per skin (lower = gentler for taller plants)
    private var skinBendCurve: CGFloat {
        if let bendCurve { return bendCurve }
        switch petSkin {
        case 1: return 2.5  // plant-1: compact, standard bend
        case 2: return 2.2  // plant-2: small stem, slightly gentler
        case 3: return 2.0  // plant-3: medium leaves
        case 4: return 1.8  // plant-4: larger leaves
        case 5: return 1.4  // plant-5: tall flower, gentlest bend
        default: return 2.0
        }
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

            // Pet with wind effect (top layer - always rendered above rock/grass)
            Image("plant-\(petSkin)")
                .resizable()
                .scaledToFit()
                .frame(height: petHeight)
                .windEffect(
                    intensity: windIntensity,
                    direction: windDirection,
                    bendCurve: skinBendCurve,
                    swayAmount: swayAmount,
                    rotationAmount: rotationAmount
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
