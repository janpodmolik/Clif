import Foundation

/// Emoji collections for speech bubble messages based on wind level.
enum EmojiSet {

    // MARK: - Wind-based Emojis

    /// Calm/happy emojis for none/low wind
    static let calmEmojis: [String] = [
        "☀️", "🌸", "🌻", "✨", "💚", "🌿", "🍀", "🌈", "💫", "🦋"
    ]

    /// Moderate emojis for medium wind
    static let moderateEmojis: [String] = [
        "🍃", "💨", "🌬️", "🌀", "💭", "⭐", "🌤️"
    ]

    /// Intense emojis for high wind
    static let intenseEmojis: [String] = [
        "🌪️", "💨", "🌧️", "😰", "🍂", "🌊", "⛈️"
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

    /// Select 1 or 2 emojis for display in speech bubble.
    /// - Parameter windLevel: Current wind intensity
    /// - Returns: Array of 1 or 2 emojis
    static func selectEmojis(for windLevel: WindLevel) -> [String] {
        let pool = emojis(for: windLevel)

        // 70% chance of 1 emoji, 30% chance of 2 emojis
        let count = Double.random(in: 0...1) < 0.3 ? 2 : 1

        return Array(pool.shuffled().prefix(count))
    }
}
