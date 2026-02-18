import SwiftUI

/// Combines body and eyes overlay for a pet.
/// Use this everywhere a pet image is displayed (thumbnails, rows, carousels, etc.).
struct PetImage: View {
    let bodyAssetName: String
    let eyesAssetName: String

    var body: some View {
        ZStack {
            Image(bodyAssetName)
                .resizable()
                .scaledToFit()
            Image(eyesAssetName)
                .resizable()
                .scaledToFit()
        }
    }
}

// MARK: - PetDisplayable Convenience

extension PetImage {
    init(_ pet: any PetDisplayable, windLevel: WindLevel = .none, isBlownAway: Bool = false) {
        self.bodyAssetName = pet.bodyAssetName(for: windLevel)
        self.eyesAssetName = pet.eyesAssetName(for: windLevel, isBlownAway: isBlownAway)
    }
}

// MARK: - PetEvolvable Convenience

extension PetImage {
    init(_ pet: any PetEvolvable, windLevel: WindLevel = .none, isBlownAway: Bool = false) {
        self.bodyAssetName = pet.bodyAssetName(for: windLevel)
        self.eyesAssetName = pet.eyesAssetName(for: windLevel, isBlownAway: isBlownAway)
    }
}
