import Foundation

/// Protocol for pet types that can be presented in UI components.
/// Combines identity, evolution data, and wind state for lists, cards, and detail views.
protocol PetPresentable: PetEvolvable {
    var id: UUID { get }
    var name: String { get }
    var purpose: String? { get }
    var windProgress: CGFloat { get }

    /// Marks pet as blown away.
    func blowAway()
}

extension PetPresentable {
    /// Wind level zone computed from wind progress (0-1).
    var windLevel: WindLevel {
        .from(progress: windProgress)
    }

    /// Current mood computed from wind level.
    var mood: Mood {
        Mood(from: windLevel)
    }
}
