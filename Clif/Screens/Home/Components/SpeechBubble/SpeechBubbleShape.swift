import SwiftUI

/// iMessage-style speech bubble shape with curved tail.
struct SpeechBubbleShape: Shape {
    /// Position of the bubble relative to pet (determines tail direction)
    /// - left: bubble is on the left of pet, tail points right
    /// - right: bubble is on the right of pet, tail points left
    let tailPosition: SpeechBubblePosition

    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height

        let bezierPath = UIBezierPath()

        if tailPosition == .right {
            // Tail on LEFT side (bubble is to the right of pet)
            // This mirrors the iMessage "received message" style
            bezierPath.move(to: CGPoint(x: 20, y: height))
            bezierPath.addLine(to: CGPoint(x: width - 15, y: height))
            bezierPath.addCurve(
                to: CGPoint(x: width, y: height - 15),
                controlPoint1: CGPoint(x: width - 8, y: height),
                controlPoint2: CGPoint(x: width, y: height - 8)
            )
            bezierPath.addLine(to: CGPoint(x: width, y: 15))
            bezierPath.addCurve(
                to: CGPoint(x: width - 15, y: 0),
                controlPoint1: CGPoint(x: width, y: 8),
                controlPoint2: CGPoint(x: width - 8, y: 0)
            )
            bezierPath.addLine(to: CGPoint(x: 20, y: 0))
            bezierPath.addCurve(
                to: CGPoint(x: 5, y: 15),
                controlPoint1: CGPoint(x: 12, y: 0),
                controlPoint2: CGPoint(x: 5, y: 8)
            )
            bezierPath.addLine(to: CGPoint(x: 5, y: height - 10))
            bezierPath.addCurve(
                to: CGPoint(x: 0, y: height),
                controlPoint1: CGPoint(x: 5, y: height - 1),
                controlPoint2: CGPoint(x: 0, y: height)
            )
            bezierPath.addLine(to: CGPoint(x: -1, y: height))
            bezierPath.addCurve(
                to: CGPoint(x: 12, y: height - 4),
                controlPoint1: CGPoint(x: 4, y: height + 1),
                controlPoint2: CGPoint(x: 8, y: height - 1)
            )
            bezierPath.addCurve(
                to: CGPoint(x: 20, y: height),
                controlPoint1: CGPoint(x: 15, y: height),
                controlPoint2: CGPoint(x: 20, y: height)
            )
        } else {
            // Tail on RIGHT side (bubble is to the left of pet)
            // This mirrors the iMessage "sent message" style
            bezierPath.move(to: CGPoint(x: width - 20, y: height))
            bezierPath.addLine(to: CGPoint(x: 15, y: height))
            bezierPath.addCurve(
                to: CGPoint(x: 0, y: height - 15),
                controlPoint1: CGPoint(x: 8, y: height),
                controlPoint2: CGPoint(x: 0, y: height - 8)
            )
            bezierPath.addLine(to: CGPoint(x: 0, y: 15))
            bezierPath.addCurve(
                to: CGPoint(x: 15, y: 0),
                controlPoint1: CGPoint(x: 0, y: 8),
                controlPoint2: CGPoint(x: 8, y: 0)
            )
            bezierPath.addLine(to: CGPoint(x: width - 20, y: 0))
            bezierPath.addCurve(
                to: CGPoint(x: width - 5, y: 15),
                controlPoint1: CGPoint(x: width - 12, y: 0),
                controlPoint2: CGPoint(x: width - 5, y: 8)
            )
            bezierPath.addLine(to: CGPoint(x: width - 5, y: height - 12))
            bezierPath.addCurve(
                to: CGPoint(x: width, y: height),
                controlPoint1: CGPoint(x: width - 5, y: height - 1),
                controlPoint2: CGPoint(x: width, y: height)
            )
            bezierPath.addLine(to: CGPoint(x: width + 1, y: height))
            bezierPath.addCurve(
                to: CGPoint(x: width - 12, y: height - 4),
                controlPoint1: CGPoint(x: width - 4, y: height + 1),
                controlPoint2: CGPoint(x: width - 8, y: height - 1)
            )
            bezierPath.addCurve(
                to: CGPoint(x: width - 20, y: height),
                controlPoint1: CGPoint(x: width - 15, y: height),
                controlPoint2: CGPoint(x: width - 20, y: height)
            )
        }

        return Path(bezierPath.cgPath)
    }
}

// MARK: - Preview

#if DEBUG
#Preview("iMessage Bubble Shape") {
    let iMessageBlue = Color(red: 0, green: 122/255, blue: 255/255)

    return VStack(spacing: 40) {
        // Left position (tail on right side) - "sent" style
        SpeechBubbleShape(tailPosition: .left)
            .fill(iMessageBlue)
            .frame(width: 70, height: 38)
            .overlay {
                Text("✨")
                    .font(.system(size: 20))
            }

        // Right position (tail on left side) - "received" style
        SpeechBubbleShape(tailPosition: .right)
            .fill(iMessageBlue)
            .frame(width: 70, height: 38)
            .overlay {
                Text("❤️")
                    .font(.system(size: 20))
            }
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
#endif
