import SwiftUI

/// A reusable modifier that applies glass effect on iOS 26+ with ultraThinMaterial fallback.
struct GlassBackgroundModifier<S: Shape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background {
                    Color.clear.glassEffect(.regular, in: shape)
                }
        } else {
            content
                .background(.ultraThinMaterial, in: shape)
        }
    }
}

/// A variant that supports tint and selection state for interactive cards.
struct GlassSelectableBackgroundModifier<S: Shape>: ViewModifier {
    let shape: S
    let isSelected: Bool
    let tintColor: Color
    let tintOpacity: CGFloat
    let strokeOpacity: CGFloat

    init(
        shape: S,
        isSelected: Bool,
        tintColor: Color,
        tintOpacity: CGFloat = 0.15,
        strokeOpacity: CGFloat = 0.3
    ) {
        self.shape = shape
        self.isSelected = isSelected
        self.tintColor = tintColor
        self.tintOpacity = tintOpacity
        self.strokeOpacity = strokeOpacity
    }

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background {
                    Color.clear
                        .glassEffect(
                            isSelected
                                ? .regular.tint(tintColor.opacity(tintOpacity))
                                : .regular,
                            in: shape
                        )
                }
                .overlay {
                    shape.stroke(
                        isSelected ? tintColor.opacity(strokeOpacity) : Color.clear,
                        lineWidth: 2
                    )
                }
        } else {
            content
                .background {
                    shape
                        .fill(isSelected ? tintColor.opacity(0.1) : Color.clear)
                        .background(.ultraThinMaterial, in: shape)
                }
                .overlay {
                    shape.stroke(
                        isSelected ? tintColor.opacity(strokeOpacity) : Color.clear,
                        lineWidth: 2
                    )
                }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Applies glass background with the given shape.
    func glassBackground<S: Shape>(in shape: S) -> some View {
        modifier(GlassBackgroundModifier(shape: shape))
    }

    /// Applies glass background with rounded rectangle.
    func glassBackground(cornerRadius: CGFloat) -> some View {
        modifier(GlassBackgroundModifier(shape: RoundedRectangle(cornerRadius: cornerRadius)))
    }

    /// Applies selectable glass background with tint support.
    func glassSelectableBackground<S: Shape>(
        in shape: S,
        isSelected: Bool,
        tintColor: Color
    ) -> some View {
        modifier(GlassSelectableBackgroundModifier(
            shape: shape,
            isSelected: isSelected,
            tintColor: tintColor
        ))
    }

    /// Applies selectable glass background with rounded rectangle.
    func glassSelectableBackground(
        cornerRadius: CGFloat,
        isSelected: Bool,
        tintColor: Color
    ) -> some View {
        modifier(GlassSelectableBackgroundModifier(
            shape: RoundedRectangle(cornerRadius: cornerRadius),
            isSelected: isSelected,
            tintColor: tintColor
        ))
    }
}
