import SwiftUI

struct ExpandableGlassMenu<Content: View, Label: View>: View, Animatable {
    var alignment: Alignment
    var progress: CGFloat
    var labelSize: CGSize = .init(width: 56, height: 56)
    var cornerRadius: CGFloat = 28
    var expandedWidth: CGFloat? = nil
    @ViewBuilder var content: Content
    @ViewBuilder var label: Label

    @State private var contentSize: CGSize = .zero

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer {
                menuContent
                    .clipShape(.rect(cornerRadius: cornerRadius))
                    .glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            }
        } else {
            menuContent
                .background(.ultraThinMaterial, in: .rect(cornerRadius: cornerRadius))
        }
    }

    private var targetWidth: CGFloat {
        expandedWidth ?? contentSize.width
    }

    private var menuContent: some View {
        let widthDiff = targetWidth - labelSize.width
        let heightDiff = contentSize.height - labelSize.height
        let rWidth = widthDiff * progress
        let rHeight = heightDiff * progress

        return ZStack(alignment: alignment) {
            content
                .compositingGroup()
                .opacity(contentOpacity)
                .onGeometryChange(for: CGSize.self) {
                    $0.size
                } action: { newValue in
                    contentSize = newValue
                }
                .frame(width: expandedWidth)
                .fixedSize(horizontal: expandedWidth == nil, vertical: true)
                .frame(
                    width: labelSize.width + rWidth,
                    height: labelSize.height + rHeight
                )

            label
                .compositingGroup()
                .opacity(1 - labelOpacity)
                .frame(width: labelSize.width, height: labelSize.height)
        }
        .compositingGroup()
    }

    private var labelOpacity: CGFloat {
        min(progress / 0.35, 1)
    }

    private var contentOpacity: CGFloat {
        max(progress - 0.35, 0) / 0.65
    }
}
