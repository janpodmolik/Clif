import SwiftUI

@MainActor
enum ShieldImageRenderer {
    private static let imageSize: CGFloat = 120
    private static let renderScale: CGFloat = 3.0

    static func saveShieldImages(
        bodyAssetName: String,
        happyEyesAssetName: String,
        neutralEyesAssetName: String
    ) {
        ShieldImagePaths.ensureDirectoryExists()

        if let happyImage = renderPetImage(bodyAssetName: bodyAssetName, eyesAssetName: happyEyesAssetName),
           let happyURL = ShieldImagePaths.happyPetImageURL {
            try? happyImage.pngData()?.write(to: happyURL, options: .atomic)
        }

        if let neutralImage = renderPetImage(bodyAssetName: bodyAssetName, eyesAssetName: neutralEyesAssetName),
           let neutralURL = ShieldImagePaths.neutralPetImageURL {
            try? neutralImage.pngData()?.write(to: neutralURL, options: .atomic)
        }
    }

    static func clearShieldImages() {
        if let url = ShieldImagePaths.happyPetImageURL {
            try? FileManager.default.removeItem(at: url)
        }
        if let url = ShieldImagePaths.neutralPetImageURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    private static func renderPetImage(bodyAssetName: String, eyesAssetName: String) -> UIImage? {
        let view = ZStack {
            Image(bodyAssetName)
                .resizable()
                .scaledToFit()
            Image(eyesAssetName)
                .resizable()
                .scaledToFit()
        }
        .frame(width: imageSize, height: imageSize)

        let renderer = ImageRenderer(content: view)
        renderer.scale = renderScale
        return renderer.uiImage
    }
}
