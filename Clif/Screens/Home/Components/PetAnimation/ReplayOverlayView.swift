import SwiftUI

/// Camera viewfinder overlay displayed during blow away replay.
/// Shows corner brackets and a pulsing red dot framing the pet area.
struct ReplayOverlayView: View {
    let isVisible: Bool
    let petFrame: CGRect

    /// Vertical padding around the pet frame
    private let verticalPadding: CGFloat = 60
    /// Horizontal inset from screen edges
    private let horizontalInset: CGFloat = 16

    @State private var isDotPulsing = false

    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let globalMinY = geometry.frame(in: .global).minY
            let localFrame = CGRect(
                x: horizontalInset,
                y: petFrame.minY - verticalPadding - globalMinY,
                width: screenWidth - horizontalInset * 2,
                height: petFrame.height + verticalPadding * 2
            )

            ZStack {
                cornerBrackets(in: localFrame)

                pulsingDot
                    .position(
                        x: localFrame.minX + 28,
                        y: localFrame.minY + 28
                    )
            }
        }
        .opacity(isVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isVisible)
        .allowsHitTesting(false)
        .onChange(of: isVisible) { _, newValue in
            isDotPulsing = newValue
        }
    }

    // MARK: - Pulsing Dot

    private var pulsingDot: some View {
        Circle()
            .fill(.red)
            .frame(width: 14, height: 14)
            .opacity(isDotPulsing ? 1.0 : 0.3)
            .animation(
                .easeInOut(duration: 0.6).repeatForever(autoreverses: true),
                value: isDotPulsing
            )
    }

    // MARK: - Corner Brackets

    private func cornerBrackets(in rect: CGRect) -> some View {
        let length: CGFloat = 30
        let thickness: CGFloat = 2.5
        let inset: CGFloat = 8

        return ForEach(Corner.allCases, id: \.self) { corner in
            cornerBracket(
                corner: corner,
                rect: rect,
                length: length,
                thickness: thickness,
                inset: inset
            )
        }
    }

    @ViewBuilder
    private func cornerBracket(
        corner: Corner,
        rect: CGRect,
        length: CGFloat,
        thickness: CGFloat,
        inset: CGFloat
    ) -> some View {
        let origin = corner.origin(in: rect, inset: inset)

        // Horizontal arm
        Rectangle()
            .fill(.white)
            .frame(width: length, height: thickness)
            .position(
                x: origin.x + (length / 2) * corner.hDirection,
                y: origin.y
            )

        // Vertical arm
        Rectangle()
            .fill(.white)
            .frame(width: thickness, height: length)
            .position(
                x: origin.x,
                y: origin.y + (length / 2) * corner.vDirection
            )
    }
}

// MARK: - Corner

private enum Corner: CaseIterable {
    case topLeading, topTrailing, bottomLeading, bottomTrailing

    var hDirection: CGFloat { isRight ? -1 : 1 }
    var vDirection: CGFloat { isBottom ? -1 : 1 }

    private var isRight: Bool { self == .topTrailing || self == .bottomTrailing }
    private var isBottom: Bool { self == .bottomLeading || self == .bottomTrailing }

    func origin(in rect: CGRect, inset: CGFloat) -> CGPoint {
        let x: CGFloat = isRight ? rect.maxX - inset : rect.minX + inset
        let y: CGFloat = isBottom ? rect.maxY - inset : rect.minY + inset
        return CGPoint(x: x, y: y)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        ReplayOverlayView(
            isVisible: true,
            petFrame: CGRect(x: 100, y: 400, width: 150, height: 150)
        )
    }
}
#endif
