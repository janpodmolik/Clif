import Foundation

/// Configuration for speech bubble appearance.
struct SpeechBubbleConfig: Equatable {
    /// Position relative to pet (left or right)
    var position: SpeechBubblePosition

    /// Emoji(s) to display (1 or 2) - used when customText is nil
    var emojis: [String]

    /// Custom text to display instead of emojis (for debug)
    var customText: String?

    /// Mood determines bubble color (sad = green SMS style, otherwise blue iMessage)
    var mood: Mood

    /// Duration visible in seconds
    var displayDuration: TimeInterval

    static let `default` = SpeechBubbleConfig(
        position: .right,
        emojis: ["😊"],
        customText: nil,
        mood: .happy,
        displayDuration: 3.0
    )
}
