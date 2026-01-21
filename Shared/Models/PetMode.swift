import Foundation
import SwiftUI

/// Mode of pet operation - determines monitoring strategy and wind calculations.
enum PetMode: String, Codable, Equatable {
    case daily
    case dynamic
}

// MARK: - Display

extension PetMode {
    var displayName: String {
        switch self {
        case .daily: "Daily Limit"
        case .dynamic: "Dynamic Mode"
        }
    }

    var description: String {
        switch self {
        case .daily: "Set a fixed daily time limit. Simple and predictable."
        case .dynamic: "Wind rises while using apps, take breaks to recover."
        }
    }
}
