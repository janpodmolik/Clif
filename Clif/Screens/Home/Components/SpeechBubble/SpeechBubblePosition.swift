import Foundation

/// Position for speech bubble relative to pet.
enum SpeechBubblePosition: String, CaseIterable {
    case left
    case right

    static func random() -> SpeechBubblePosition {
        allCases.randomElement() ?? .right
    }
}
