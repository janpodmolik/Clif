import Foundation

/// Mode of pet operation - determines monitoring strategy and wind calculations.
enum PetMode: String, Codable, Equatable {
    case daily
    case dynamic
}
