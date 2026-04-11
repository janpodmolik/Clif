import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

/// Essence determines which evolution path a pet follows.
/// This is a pure identifier - all evolution logic lives in EvolutionPath.
/// Raw values are stable numeric IDs for database storage. Display names live in `name`.
enum Essence: Int, Codable, CaseIterable, Identifiable, Transferable {
    var id: Int { rawValue }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .essence)
    }

    // Nature (100–199)
    case plant = 100
    case moss = 101
    case shroom = 102
    case tree = 103

    // Fantasy creatures (200–299)
    case troll = 200
    case orc = 201
    case dreamy = 202

    // Animals (300–399)
    case lion = 300
    case racoon = 301

    // Crafted / Special (400–499)
    case clicker = 400
    case stitches = 401

    /// Client-side name used for asset paths and display. Decoupled from the numeric ID.
    var name: String {
        switch self {
        case .plant: "plant"
        case .troll: "troll"
        case .orc: "orc"
        case .clicker: "clicker"
        case .lion: "lion"
        case .stitches: "stitches"
        case .racoon: "racoon"
        case .moss: "moss"
        case .shroom: "shroom"
        case .tree: "tree"
        case .dreamy: "dreamy"
        }
    }

    /// Essences unlocked by default for all users.
    static let defaultUnlocked: Set<Essence> = [.plant]

    /// Price in Ucoins to unlock this essence.
    var price: Int {
        switch self {
        case .plant: return 0
        case .troll: return 250
        case .orc: return 225
        case .clicker: return 150
        case .lion: return 200
        case .stitches: return 150
        case .racoon: return 150
        case .moss: return 150
        case .shroom: return 150
        case .tree: return 200
        case .dreamy: return 200
        }
    }

    /// Asset path for essence icon: "evolutions/plant/essence"
    var assetName: String {
        "evolutions/\(name)/essence"
    }

    // MARK: - Catalog Metadata

    var catalogDescription: String {
        switch self {
        case .plant: return String(localized: "A path of growth and calm. Your Uuumi evolves as a plant.")
        case .troll: return String(localized: "A path of strength and courage. Your Uuumi evolves as a troll.")
        case .orc: return String(localized: "A path of wildness and fury. Your Uuumi evolves as an orc.")
        case .clicker: return String(localized: "A path of speed and reflexes. Your Uuumi evolves as a clicker.")
        case .lion: return String(localized: "A path of courage and majesty. Your Uuumi evolves as a lion.")
        case .stitches: return String(localized: "A path of creativity and transformation. Your Uuumi evolves as stitches.")
        case .racoon: return String(localized: "A path of cunning and resourcefulness. Your Uuumi evolves as a racoon.")
        case .moss: return String(localized: "A path of nature and harmony. Your Uuumi evolves as moss.")
        case .shroom: return String(localized: "A path of mystery and spores. Your Uuumi evolves as a shroom.")
        case .tree: return String(localized: "A path of wisdom and roots. Your Uuumi evolves as a tree.")
        case .dreamy: return String(localized: "A path of dreams and wonder. Your Uuumi evolves into a dreamy creature.")
        }
    }

    var rarity: EssenceRarity {
        switch self {
        case .plant: return .common
        case .troll: return .rare
        case .orc: return .rare
        case .clicker: return .rare
        case .lion: return .rare
        case .stitches: return .rare
        case .racoon: return .rare
        case .moss: return .rare
        case .shroom: return .rare
        case .tree: return .rare
        case .dreamy: return .rare
        }
    }
}

// MARK: - Rarity

enum EssenceRarity: String, Codable {
    case common
    case rare
    case legendary

    var displayName: String {
        switch self {
        case .common: return String(localized: "Common")
        case .rare: return String(localized: "Rare")
        case .legendary: return String(localized: "Legendary")
        }
    }

    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .legendary: return .orange
        }
    }
}

extension UTType {
    static let essence = UTType(exportedAs: "com.uuumi.essence")
}
