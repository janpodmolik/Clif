import SwiftUI

/// Speech bubble displaying emoji(s) next to the pet.
/// Uses iMessage-style bubble shape with curved tail.
struct SpeechBubbleView: View {
    let config: SpeechBubbleConfig
    let isVisible: Bool

    /// Horizontal offset from pet center
    var horizontalOffset: CGFloat = 85
    /// Vertical offset from pet center (negative = above)
    var verticalOffset: CGFloat = -60

    /// iMessage blue color (happy/neutral mood)
    private let iMessageBlue = Color(red: 0, green: 122/255, blue: 255/255)

    /// SMS green color (sad mood) - Apple #34C759
    private let smsGreen = Color(red: 52/255, green: 199/255, blue: 89/255)

    /// Bubble color based on mood
    private var bubbleColor: Color {
        config.mood == .sad ? smsGreen : iMessageBlue
    }

    /// Whether displaying custom text or emojis
    private var hasCustomText: Bool {
        config.customText != nil && !config.customText!.isEmpty
    }

    /// Bubble dimensions - dynamically sized for text
    private var bubbleWidth: CGFloat {
        if hasCustomText {
            // Wider for text content
            let textLength = config.customText!.count
            return min(max(CGFloat(textLength * 8 + 30), 60), 200)
        }
        return config.emojis.count > 1 ? 70 : 50
    }

    private var bubbleHeight: CGFloat {
        38
    }

    private var bubbleOffset: CGFloat {
        config.position == .left ? -horizontalOffset : horizontalOffset
    }

    /// Offset to center content within the asymmetric bubble shape
    /// The tail takes up space on one side, so we shift content away from tail
    private var contentCenteringOffset: CGFloat {
        // Tail is ~8px, so shift content by half that amount away from tail
        config.position == .left ? -4 : 4
    }

    var body: some View {
        ZStack {
            // Background: iMessage-style bubble (blue for happy/neutral, green for sad)
            SpeechBubbleShape(tailPosition: config.position)
                .fill(bubbleColor)
                .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)

            // Content - custom text or emojis (centered with offset for tail)
            Group {
                if hasCustomText {
                    Text(config.customText!)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                } else {
                    HStack(spacing: 2) {
                        ForEach(config.emojis, id: \.self) { emoji in
                            Text(emoji)
                                .font(.system(size: 20))
                        }
                    }
                }
            }
            .offset(x: contentCenteringOffset)
        }
        .frame(width: bubbleWidth, height: bubbleHeight)
        .offset(x: bubbleOffset, y: verticalOffset)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.5)
        .animation(
            isVisible
                ? .spring(response: 0.3, dampingFraction: 0.6)
                : .easeOut(duration: 0.2),
            value: isVisible
        )
    }
}

// MARK: - Preview

#if DEBUG
#Preview("Speech Bubble - Happy (Blue)") {
    ZStack {
        Color.blue.opacity(0.3)

        Circle()
            .fill(.green)
            .frame(width: 80, height: 80)

        SpeechBubbleView(
            config: SpeechBubbleConfig(
                position: .right,
                emojis: ["😊", "❤️"],
                mood: .happy,
                displayDuration: 3.0
            ),
            isVisible: true
        )
    }
}

#Preview("Speech Bubble - Sad (Green)") {
    ZStack {
        Color.blue.opacity(0.3)

        Circle()
            .fill(.green)
            .frame(width: 80, height: 80)

        SpeechBubbleView(
            config: SpeechBubbleConfig(
                position: .left,
                emojis: ["😢", "💔"],
                mood: .sad,
                displayDuration: 3.0
            ),
            isVisible: true
        )
    }
}
#endif
