import CoreTransferable
import SwiftUI
import UniformTypeIdentifiers

/// Essence determines which evolution path a pet follows.
/// This is a pure identifier - all evolution logic lives in EvolutionPath.
enum Essence: String, Codable, CaseIterable, Transferable {
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .essence)
    }

    case plant
    // Future: crystal, flame, water

    /// Asset path for essence icon: "evolutions/plant/essence"
    var assetName: String {
        "evolutions/\(rawValue)/essence"
    }

    // MARK: - Catalog Metadata

    var catalogDescription: String {
        switch self {
        case .plant: return "Cesta růstu a klidu. Tvůj pet se vyvíjí jako rostlina."
        }
    }

    var rarity: EssenceRarity {
        switch self {
        case .plant: return .common
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
        case .common: return "Běžná"
        case .rare: return "Vzácná"
        case .legendary: return "Legendární"
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
