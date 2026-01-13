/// Essence determines which evolution path a pet follows.
/// This is a pure identifier - all evolution logic lives in EvolutionPath.
enum Essence: String, Codable, CaseIterable {
    case plant
    // Future: crystal, flame, water

    /// Asset path for essence icon: "evolutions/plant/essence"
    var assetName: String {
        "evolutions/\(rawValue)/essence"
    }
}
