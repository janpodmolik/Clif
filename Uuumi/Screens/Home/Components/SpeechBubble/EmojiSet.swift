import Foundation

/// Emoji collections for speech bubble messages based on wind level.
enum EmojiSet {

    // MARK: - Wind-based Emojis

    /// Calm/happy emojis for none/low wind
    static let calmEmojis: [String] = [
        "♥️", "👋", "😁", "😊", "✌️", "😍", "🤩",
    ]

    /// Moderate emojis for medium wind
    static let moderateEmojis: [String] = [
        "😐", "😶", "🤔", "🥺", "😬", "🙃", "😅", "🫤", "🥲",
    ]

    /// Intense emojis for high wind
    static let intenseEmojis: [String] = [
        "😰", "😨", "😵‍💫", "😣", "😭", "🫣", "😕", "😡", "🫨",
    ]

    // MARK: - Selection Logic

    /// Returns emoji pool for given wind level.
    static func emojis(for windLevel: WindLevel) -> [String] {
        switch windLevel {
        case .none, .low: return calmEmojis
        case .medium: return moderateEmojis
        case .high: return intenseEmojis
        }
    }

    /// Select a random emoji for display in speech bubble.
    static func selectEmoji(for windLevel: WindLevel) -> String {
        emojis(for: windLevel).randomElement()!
    }
}
