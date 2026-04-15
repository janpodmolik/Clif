import Foundation

enum ShieldImagePaths {
    private static var containerURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: AppConstants.appGroupIdentifier
        )
    }

    private static var directoryURL: URL? {
        containerURL?.appendingPathComponent("shield_images", isDirectory: true)
    }

    static var happyPetImageURL: URL? {
        directoryURL?.appendingPathComponent("pet_happy.png")
    }

    static var neutralPetImageURL: URL? {
        directoryURL?.appendingPathComponent("pet_neutral.png")
    }

    static func ensureDirectoryExists() {
        guard let directory = directoryURL else { return }
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
}
