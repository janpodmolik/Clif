import Foundation

/// Source for emoji selection in speech bubbles.
enum EmojiSource: String, CaseIterable {
    case mood = "Mood"
    case random = "Random"
}

/// Emoji collections organized by mood for speech bubble messages.
enum EmojiSet {

    // MARK: - Mood-based Emojis

    static let happyEmojis: [String] = [
        "❤️", "😊", "🌟", "✨", "🎉", "💪", "🌈", "😄", "🥳", "💖", "🌸", "🎶"
    ]

    static let neutralEmojis: [String] = [
        "🤔", "😐", "💭", "🙂", "😶", "🧐", "💫", "⭐", "👀", "🫤"
    ]

    static let sadEmojis: [String] = [
        "😢", "💔", "😞", "🥺", "😔", "💧", "🌧️", "😿", "😥", "🫠"
    ]

    // MARK: - Random Pool

    static let randomEmojis: [String] = [
        "❤️", "😊", "🌟", "✨", "🎉", "💪", "🌈", "😄", "🥳", "💖",
        "🔥", "👋", "🎵", "💯", "🙌", "😎", "🌻", "⚡", "🍀", "🦋"
    ]

    // MARK: - Selection Logic

    /// Returns emoji array for given mood.
    static func emojis(for mood: Mood) -> [String] {
        switch mood {
        case .happy: return happyEmojis
        case .neutral: return neutralEmojis
        case .sad, .blown: return sadEmojis
        }
    }

    /// Select 1 or 2 emojis for display in speech bubble.
    /// - Parameters:
    ///   - source: Which emoji selection source to use
    ///   - mood: Current pet mood
    /// - Returns: Array of 1 or 2 emojis
    static func selectEmojis(source: EmojiSource, mood: Mood) -> [String] {
        let pool: [String]

        switch source {
        case .mood:
            pool = emojis(for: mood)
        case .random:
            pool = randomEmojis
        }

        // 70% chance of 1 emoji, 30% chance of 2 emojis
        let count = Double.random(in: 0...1) < 0.3 ? 2 : 1

        return Array(pool.shuffled().prefix(count))
    }
}
